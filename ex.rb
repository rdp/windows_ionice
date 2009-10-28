require 'frubygems'
require 'sane'
require 'ruby-wmi'
#all = WMI::Win32_PerfFormattedData_PerfProc_Process.find(:all)
#all.map &:Refresh_
#all.map &:Refresh_ # for some reason have to run it twice
#puts all.map &:PercentProcessorTime # will be the real values
require 'benchmark'
# this is snapshot of raw data per process
# including
WMI::Win32_PerfRawData_PerfProc_Process.find(:all)[0].PercentProcessorTime
# and also the PID


def fill into_this
  all = WMI::Win32_PerfRawData_PerfProc_Process.find(:all).each{|proc|
    into_this[proc.IDProcess] = proc.PercentProcessorTime.to_i
  }
  all[0].TimeStamp_Sys100NS.to_i # these are all the same
end

# anticipate {123 => 456}

def diff_values first, second, time_diff
  answer = {}
  for key in first.keys
    if first[key] != second[key]
      begin
        answer[key] = (first[key] - second[key]).to_f/time_diff*100
      rescue
        # sometimes the values are nil
        # ignore I suppose
      end
    end
  end
  answer
end

loop {
  puts '.'
  old = {}

  ts1 = fill old
  sleep 3
  new = {}
  ts2 = fill new

  sorted = diff_values( new, old, ts2 - ts1 )
  puts sorted.inspect if $VERBOSE
  violated = []
  sorted.each{|pid, percentage|
    if percentage >= 98 && pid != 0 # using a full core (100) or more...
      violated << pid
      proc =WMI::Win32_Process.find(:first,  :conditions => {:ProcessId => pid.to_i})
      if proc.Priority > 4 # appears that 7 or 8 here mean normal prio...
        proc.SetPriority 64 # set it to low priority
        puts "violated!", pid
      end
    end
  }
}
