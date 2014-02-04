#######################################################################
# example_job.rb
#
# Simple example script for futzing with Windows Jobs. This will fire
# up two instances of notepad and add them to the job, then close
# them.
#######################################################################
require 'win32/job'
include Win32

pid1 = Process.spawn("notepad.exe")
pid2 = Process.spawn("notepad.exe")
sleep 0.5

j = Job.new('test')

j.configure_limit(
  :breakaway_ok      => true,
  :kill_on_job_close => true,
  :process_memory    => 1024 * 8,
  :process_time      => 1000
)

j.add_process(pid1)
j.add_process(pid2)

sleep 0.5

j.close # Notepad instances should terminate here, too.
