#include <stdint.h>

#include "moonbit.h"

static moonbit_bytes_t mb_empty_terminal_size(void) {
  return moonbit_make_bytes(0, 0);
}

static moonbit_bytes_t mb_make_terminal_size(int width, int height) {
  if (width <= 0 || height <= 0) {
    return mb_empty_terminal_size();
  }

  uint8_t *result = (uint8_t *)moonbit_make_bytes(4, 0);
  result[0] = (uint8_t)((width >> 8) & 0xff);
  result[1] = (uint8_t)(width & 0xff);
  result[2] = (uint8_t)((height >> 8) & 0xff);
  result[3] = (uint8_t)(height & 0xff);
  return (moonbit_bytes_t)result;
}

#ifdef _WIN32

#include <windows.h>

static DWORD mb_stream_kind_to_handle_id(int32_t stream_kind) {
  switch (stream_kind) {
  case 0:
    return STD_OUTPUT_HANDLE;
  case 1:
    return STD_ERROR_HANDLE;
  case 2:
    return STD_INPUT_HANDLE;
  default:
    return STD_OUTPUT_HANDLE;
  }
}

MOONBIT_FFI_EXPORT moonbit_bytes_t mb_terminal_size_probe(int32_t stream_kind) {
  HANDLE handle = GetStdHandle(mb_stream_kind_to_handle_id(stream_kind));
  if (handle == NULL || handle == INVALID_HANDLE_VALUE) {
    return mb_empty_terminal_size();
  }

  CONSOLE_SCREEN_BUFFER_INFO info;
  if (!GetConsoleScreenBufferInfo(handle, &info)) {
    return mb_empty_terminal_size();
  }

  int width = (int)(info.srWindow.Right - info.srWindow.Left + 1);
  int height = (int)(info.srWindow.Bottom - info.srWindow.Top + 1);
  return mb_make_terminal_size(width, height);
}

#elif defined(__unix__) || defined(__APPLE__)

#include <sys/ioctl.h>
#include <unistd.h>

static int mb_stream_kind_to_fd(int32_t stream_kind) {
  switch (stream_kind) {
  case 0:
    return STDOUT_FILENO;
  case 1:
    return STDERR_FILENO;
  case 2:
    return STDIN_FILENO;
  default:
    return -1;
  }
}

MOONBIT_FFI_EXPORT moonbit_bytes_t mb_terminal_size_probe(int32_t stream_kind) {
  int fd = mb_stream_kind_to_fd(stream_kind);
  if (fd < 0) {
    return mb_empty_terminal_size();
  }

  struct winsize size;
  size.ws_col = 0;
  size.ws_row = 0;
  size.ws_xpixel = 0;
  size.ws_ypixel = 0;

  if (ioctl(fd, TIOCGWINSZ, &size) != 0) {
    return mb_empty_terminal_size();
  }

  return mb_make_terminal_size((int)size.ws_col, (int)size.ws_row);
}

#else

MOONBIT_FFI_EXPORT moonbit_bytes_t mb_terminal_size_probe(int32_t stream_kind) {
  (void)stream_kind;
  return mb_empty_terminal_size();
}

#endif
