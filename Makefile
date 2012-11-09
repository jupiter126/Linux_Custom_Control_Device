TARGET = getscancodes
SOURCES = getscancodes.c

CFLAGS=-O2 -Wall
CC=gcc

OBJECTS=$(SOURCES:.c=.o)

all: $(TARGET)

cc:
	$(MAKE) CC=cc \
		all

$(TARGET): $(OBJECTS)
	$(CC) -o  $@ $(OBJECTS)

clean:
	$(RM) $(TARGET) $(OBJECTS)
