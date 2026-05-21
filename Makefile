PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
CFLAGS ?= -O2 -Wall -Wextra

BUILDDIR = build
TARGET = $(BUILDDIR)/msi-ez120-sync
SRC = src/ez120-sync.c

.PHONY: all install clean

all: $(TARGET)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(TARGET): $(SRC) | $(BUILDDIR)
	gcc $(CFLAGS) -o $@ $<

install: $(TARGET)
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 $(TARGET) "$(DESTDIR)$(BINDIR)/$(TARGET)"

clean:
	rm -rf $(BUILDDIR)
