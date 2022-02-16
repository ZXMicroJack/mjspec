#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <stdint.h>

int
set_interface_attribs (int fd, int speed, int parity) {
  struct termios tty;
  if (tcgetattr (fd, &tty) != 0) {
    printf ("error %d from tcgetattr", errno);
    return -1;
  }

  cfsetospeed (&tty, speed);
  cfsetispeed (&tty, speed);

  tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
  // disable IGNBRK for mismatched speed tests; otherwise receive break
  // as \000 chars
  tty.c_iflag &= ~IGNBRK;         // disable break processing
  tty.c_lflag = 0;                // no signaling chars, no echo,
                                  // no canonical processing
  tty.c_oflag = 0;                // no remapping, no delays
  tty.c_cc[VMIN]  = 0;            // read doesn't block
  tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

  tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl
  tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,

  // enable reading
  tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
  tty.c_cflag |= parity;
  tty.c_cflag &= ~CSTOPB;
  tty.c_cflag &= ~CRTSCTS;

  if (tcsetattr (fd, TCSANOW, &tty) != 0) {
    printf ("error %d from tcsetattr", errno);
    return -1;
  }
  return 0;
}

void
set_blocking (int fd, int should_block) {
  struct termios tty;
  memset (&tty, 0, sizeof tty);
  if (tcgetattr (fd, &tty) != 0) {
    printf ("error %d from tggetattr", errno);
    return;
  }

  tty.c_cc[VMIN]  = should_block ? 1 : 0;
  tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

  if (tcsetattr (fd, TCSANOW, &tty) != 0) {
    printf ("error %d setting term attributes", errno);
  }
}

int readLine(int fd, char line[], int max, int timeout) {
  int quit = 0;
  char buf;
  int lineLen = 0;

  unsigned long exitTime = time(NULL) + timeout;

  while (lineLen < (max-1) && time(NULL) < exitTime) {
    int r = read (fd, &buf, 1);
    if (r > 0) {
      // printf("[rx:%c]", buf);
      if ((buf == '\n' || buf == '\r') && lineLen > 0) {
        break;
      } else if (buf != '\r' && buf != '\n') {
        line[lineLen++] = buf;
      }
    } else if (r == 0) {
      break;
    }
  }
  line[lineLen] = '\0';
  return lineLen;
}

void monitor(int fd, const char *end) {
  char buff[256];
  int len;
  for(;;) {
    len = readLine(fd, buff, sizeof buff, 1);
    if (len) {
      printf("-> %s\n", buff);
      if (!strncmp(buff, end, strlen(end))) {
          return;
      }
    }
  }
}

int _write(int fd, char *s, int n) {
	int sent = 0;
	while (sent < n) {
		sent += write(fd, s+sent, n-sent);
	}
	return sent;
}

// uint8_t *readMCS(const char *mcs) {
// }

void drain(int fd) {
  char buf[100];
  while (read (fd, buf, sizeof buf))
    ;
}

uint8_t hex2nybble(char c) {
	if (c >= '0' && c <= '9') return c - '0';
	if (c >= 'a' && c <= 'f') return c - 'a' + 10;
	if (c >= 'A' && c <= 'F') return c - 'A' + 10;
	return 0xff;
}
uint8_t hex2bin(char *s) {
	return (hex2nybble(s[0]) << 4) | hex2nybble(s[1]);
}

int handleSRline(char *s, uint8_t *buf) {
	uint8_t rec[256];
	int len = 0;
	
	printf("-> %s\n", s);
	for (int i=1; i<strlen(s); i+=2) {
		rec[len++] = hex2bin(&s[i]);
	}
	
	if (rec[3] == 0x00) {
		memcpy(buf, &rec[4], rec[0]);
		return rec[0];
	}
	
	return 0;
}

int readSR(const char *fn, uint8_t *buf, int len) {
	int got = 0;
	char s[1024];
	int i = 0;

	FILE *f = fopen(fn, "rb");
	
	int c = fgetc(f);
	while (!feof(f)) {
		if (c != '\r' && c != '\n') s[i++] = c;
		else if (i > 0) {
			s[i] = '\0';
			int thisLen = handleSRline(s, buf);
			buf += thisLen;
			got += thisLen;
			i = 0;
		}
		c = fgetc(f);
	}
	fclose(f);
	return got;
}

uint8_t binfile[1024*1024];
int main(int argc, char **argv) {
  const char *portnameUsbJTAG = "/dev/ttyACM0";

	FILE *f = fopen(argv[1], "rb");
	if (!f) {
		printf("Error: Cannot open file\n");
		return 1;
	}
	
	printf("Info: open serial\n");
  int fd = open (portnameUsbJTAG, O_RDWR | O_NOCTTY | O_SYNC);
  if (fd < 0) {
    printf ("Error: %d opening %s: %s - trying USB port\n", errno, portnameUsbJTAG, strerror (errno));
		fclose(f);
    return 1;
  }

  printf("set settings\n");
  set_interface_attribs (fd, B115200, 0);  // set speed to 115,200 bps, 8n1 (no parity)
  set_blocking(fd, 1);

	int ch = fgetc(f);
	char str[10];
	while (!feof(f)) {
		sprintf(str, "%02X", ch);
		_write(fd, str, 1);
		_write(fd, &str[1], 1);
		ch = fgetc(f);
	}
	_write(fd, "\r", 1);
	printf("\n");
	
	printf("Info: ready\n");
  fclose(f);

// 	drain(fd);
	// feed binary in if needed
  set_blocking(fd, 1);
	if (argc > 2) {
		char buf;
		memset(binfile, 0xff, sizeof binfile);
		int binlen;
		
		if (argv[2][0] == '-') {
			FILE *f = fopen(&argv[2][1], "rb");
			binlen = fread(binfile, 1, sizeof binfile, f);
			fclose(f);
		} else {
			binlen = readSR(argv[2], binfile, sizeof binfile);
		}
		
		int pos = 0;

		int r = read (fd, &buf, 1);
		printf("r:%d buf:%c\n", r, buf);
		while (buf != 'x') {
			if (buf == 's') {
				_write(fd, &binfile[pos], 256);
				pos += 256;
			}
			if (buf == 'r') {
				if (pos >= 256) pos -= 256;
				_write(fd, &binfile[pos], 256);
				pos += 256;
			}
			if (buf == 'h') {
				_write(fd, &buf, 1);
			}
			r = read(fd, &buf, 1);
		}
	}

	close(fd);
  return 0;
}
