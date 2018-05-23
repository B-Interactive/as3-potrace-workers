# ActionScript 3.0 Potrace with Workers demo

A conslidated version of a live project where the as3potrace port was used to convert a live video stream into a traced vector.

Makes use of any specified number of workers, limited only by hardware (Release builds tested up to 8 threads).

	
Dependencies
------------

* Adobe AIR SDK 29 (a newer, or older SDK is probably fine) [download](https://helpx.adobe.com/air/kb/archived-air-sdk-version.html)
* [as3potrace] (https://wahlers.com.br/claus/blog/as3-bitmap-tracer-vectorizer-as3potrace/) Claus Wahlers' port of potrace 1.8 to ActionScript 3.0.


Acknowledgements
----------------
* Peter Selinger, creator of potrace: http://potrace.sourceforge.net/
* Jackson Dunstan for sharing his experiments with AIR workers: https://jacksondunstan.com/
* Adobe for creating and continuing to maintain the awesome AIR framework.


License
-------
Copyright (C) 2018 David Armstrong (demo)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.



as3potrace
Copyright (C) 2001-2010 Peter Selinger (potrace)
Copyright (C) 2009 Wolfgang Nagl (Vectorization)
Copyright (C) 2011 Claus Wahlers (as3potrace)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301, USA.