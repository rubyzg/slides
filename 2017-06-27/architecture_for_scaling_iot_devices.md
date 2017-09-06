Outline
=======


* architecture
* design
* coding





























Problem(s)
==========
Problem
-------
- scaling IoT device connections



      +------------+         +------------+
      | Controller |  ====>  |            |
      +------------+         |            |
           ...               |   Server   |
      +------------+         |            |
      | Controller | =====>  |            |
      +------------+         +------------+




- Limit 1024 connects

- Things slow down at 100 connections

- A big $$ customer  :)
  o 500 new devices this year

- Very strict requirements: downtime or slowness is NOT
  an option (otherwise less revenue for the customer)


*Other problems*

- dirty design
- crappy C code
  - manually assembled JSON











Easy solution
-------------

- Scale the existing solution

                           'foo.mycompany.com'
      +------------+         +-------------+
      | Controller |  ====>  |             |
      +------------+         |             |
           ...               |  Server 1   |
      +------------+         |             |
      | Controller | =====>  |             |
      +------------+         +-------------+



                           'bar.mycompany.com'
      +------------+         +-------------+
      | Controller |  ====>  |             |
      +------------+         |             |
           ...               |  Server N   |
      +------------+         |             |
      | Controller | =====>  |             |
      +------------+         +-------------+


- Hostnames are *hardcoded* on controllers. Changing is hard.

- Need to have a single interface (single URL).
  Radical simplicity where things are hard to change.







Proper solution
---------------

- rethink everything

- full rewrite


The rest of the speech is about this.
























Architecture
============
High level
----------





                     'foo.mycompany.com'
  +------------+       +--------------+        +----------------+         +--------------+          +---------------+
  | Controller |  ==>  |              |  ==>   | Driver Process |  <===>  |              |          |               |
  +------------+       |     Load     |        +----------------+         |    Vendor    |          |    Main app   |
      ..(n)..          |   balancer   |        +----------------+         |      app     |   <==>   |               |
  +------------+       | (single URL) |  ==>   | Driver Process |  <===>  |   (with DB)  |          |   (web API,   |
  | Controller |  ==>  |              |        +----------------+         |              |          |   admin UI)   |
  +------------+       +--------------+               ..(n)..             +--------------+          +---------------+
                                               +----------------+       /
                                         ==>   | Driver Process |  <===/
                                               +----------------+





















Process level
-------------

* notes

                      Driver Process                                         Vendor app
                       (40 in prod)
           +-----------------------------------+                    +----------------------------+
           |                                   |                    |                            |
           |            Ruby layer             |    GRPC (2 way)    |          Rails             |
           |                                  <==========//==========>                          <== GRPC ==>   Main app
           |                                   |                    |                            |
           |              Event                |                    |     - Event processing     |
           |            & command              |                    |     - Events to DB         |
           |            processing            <==========//===========                           |
           |                                   |    Redis pub/sub   |                            |
           |                                   |      (1 way)       |                            |
           |        events       commands      |                    |                            |
           |          ^             |          |                    +----------------------------+
           |~~~~~~~~~~|~~~~~~~~~~~~~|~~~~~~~~~~|
           |          |             v          |
           |           C lang layer            |
   port x <=>                                  |
           |             libmpl.a              |
           |             scp_net.h             |
           |             ...                   |
           +-----------------------------------+














Design
======

                                               Driver process

          +-----------------------------------------------------------------------------------+
          |      C layer           /                 Ruby layer                               |
          |                        \       +----------------------------------------------+   |
          |                        /       |            Event processing thread           |   |
          |                        \       |                                              |   |     GRPC
          |      scpGetMessage() ============> Driver::API.fetch_event                   >================//========>  vendor app
          |                        /       |                                              |   |
          |                        \       |                                              |   |
          |                        /       +----------------------------------------------+   |
          |                        \                                                          |
          |                        /                                                          |
          |                        \                                                          |
          |     libmpl.a           /       +----------------------------------------------+   |
          |     scp_net.h          \       |            Command sending thread 1          |   |
  port x <=>    ...                /       |                                              |   |
          |                        \       |                                            <========  redis.subscribe(controller.serial_num)
          |                        /       |  Driver::API.send_command(command)           |   |
          |                        \       | v                                            |   |
          |                        /       +-|--------------------------------------------+   |
          |                        \         |                   .                            |
          |  scpConfigCommand()  <===========+                   .                            |
          |                        /         |                   .                            |
          |                        \       +-|--------------------------------------------+   |
          |                        /       | |          Command sending thread 20         |   |
          |                        \       | ^                                            |   |
          |                        /       |  Driver::API.send_command(command)         <========  redis.subscribe(controller.serial_num)
          |                        \       |                                              |   |
          |                        /       |                                              |   |
          |                        \       +----------------------------------------------+   |
          |                        /                                                          |
          |                        \                                                          |
          |                        /                                                          |
          |                        \                                                          |
          +-----------------------------------------------------------------------------------+





Coding
======
Intro
-----
- C extension


- App is plain ruby (memory requirements)
  o 30 Mb RAM per process (in QA)


- Gems used (4):
  o dotenv            for env vars (3 of them)
  o grpc              interprocess communication
  o redis             interprocess communication
  o sentry-raven      exception reporting


- Raw thread manipulation
  Is not as hard as it seems


















Ruby FFI
--------

- Super easy to start with

- Everything written in Ruby, NO C code, no compiling!

- BUT, C structs and enums need to be all
  precisely specified/written in Ruby

* Our experience
  - lots of segfaults
  - writing ~1000 LOC of Ruby code for C structs :(
  - risk for production

* Lessons learned
  - great for just calling C functions
  - avoid if you have lot of C structs



















Ruby C extensions
-----------------

- Mature technology

- Requires compilation and writing C code

- Works with statically compiled libraries example: 'libfoo.a'
  (FFI works only with dynamically linked libraries)

* Our experience
  - super stable after the compilation and C-code debugging phase
  - Gets the job done
  - Can work with Ruby threads (FFI can't)

* Lessons learned
  - If not sure, use C extensions




















How do you build a long-running ruby process?
---------------------------------------------
- use a loop

  class EventLoop
    def start
      loop do
        event = Driver.fetch_event
        handle event
      end
    end
  end
























C extensions and Ruby threads bug
---------------------------------

* 2 bugs
  (show Design pic)


- requires wrapping "interruptable" blocking C function with

  `rb_thread_call_without_gvl()`

  and passing appropriate flags as args

























Changing process name
---------------------

- just write to '$0'

  class ProgramName
    def self.update(name)
      $0 = name
    end
  end


- benefit: exposing internal process info

  $ ps aux | grep ...
    mercury-driver v4.6.1.212 port: 5001 sequences: 0 controllers:
    mercury-driver v4.6.1.212 port: 5002 sequences: 7 controllers: 61364
    mercury-driver v4.6.1.212 port: 5003 sequences: 3 controllers: 12345, 67890




















Lesson learned when working with threads
----------------------------------------


- class state is SHARED across threads

  class Foo
    def self.bar=(value)
      @bar = value
    end

    def self.bar
      @bar
    end
  end


- use thread local variables instead

  class Foo
    def self.bar=(value)
      Thread.current[:bar] = value
    end

    def self.bar
      Thread.current[:bar]
    end
  end












Questions ?
===========
