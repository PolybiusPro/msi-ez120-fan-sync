PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
CFLAGS ?= -O2 -Wall -Wextra

TARGET = msi-ez120-sync
SRC = src/ez120-sync.c

.PHONY: all install clean

all: $(TARGET)

$(TARGET): $(SRC)
	gcc $(CFLAGS) -o $@ $<

install: $(TARGET)
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 $(TARGET) "$(DESTDIR)$(BINDIR)/$(TARGET)"

clean:
	rm -f $(TARGET)
