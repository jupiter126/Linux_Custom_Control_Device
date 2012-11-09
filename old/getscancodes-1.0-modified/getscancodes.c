/*---------------------------------------------------------------------------------
Name               : getscancodes.c
Author             : Marvin Raaijmakers
Description        : Shows the scancode of the pressed or released key.
Line 93 Modified by Kon for JuPiTeR
Date of last change: 3-Sept-2005

    Copyright (C) 2005 Marvin Raaijmakers

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

    You can contact me at: marvinr(at)users(dot)sf(dot)net
    (replace (at) by @ and (dot) by .)
-----------------------------------------------------------------------------------*/
#include <stdint.h>

#include <linux/input.h>

#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

#ifndef EV_SYN
#define EV_SYN 0
#endif

int
main (int argc, char **argv)
{
	int fd, rd, i;
	struct input_event ev[64];
	int version;
	unsigned short id[4];
	char name[256] = "Unknown";

	if (argc < 2)
	{
		printf("Usage: %s /dev/input/eventX\n", argv[0]);
		printf("Where X = input device number\n");
		return 1;
	}

	if ((fd = open(argv[argc - 1], O_RDONLY)) < 0)
	{
		perror("getscancodes");
		return 1;
	}

	if (ioctl(fd, EVIOCGVERSION, &version))
	{
		perror("getscancodes: can't get version");
		return 1;
	}

	printf("Input driver version is %d.%d.%d\n",
		version >> 16, (version >> 8) & 0xff, version & 0xff);

	ioctl(fd, EVIOCGID, id);
	printf("Input device ID: bus 0x%x vendor 0x%x product 0x%x version 0x%x\n",
		id[ID_BUS], id[ID_VENDOR], id[ID_PRODUCT], id[ID_VERSION]);

	ioctl(fd, EVIOCGNAME(sizeof(name)), name);
	printf("Input device name: \"%s\"\n", name);

	while (1) {
		rd = read(fd, ev, sizeof(struct input_event) * 64);

		if (rd < (int) sizeof(struct input_event)) {
			printf("yyy\n");
			perror("\ngetscancodes: error reading");
			return 1;
		}

		for (i = 0; i < rd / sizeof(struct input_event); i++)
		{
			if (ev[i].type != EV_SYN &&
			    ev[i].type == EV_MSC &&
			    (ev[i].code == MSC_RAW || ev[i].code == MSC_SCAN))
			{
				char buf[8]; sprintf(buf, "%d\n", ev[i].value); write(1, buf, sizeof(buf)); fsync(1);
			}
		}
	}
}
