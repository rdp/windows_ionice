require 'frubygems'
require 'sane'
require 'ruby-wmi'

#all = WMI::Win32_PerfFormattedData_PerfProc_Process.find(:all)
#all.map &:Refresh_
#all.map &:Refresh_ # for some reason have to run it twice
#puts all.map &:PercentProcessorTime # will be the real values

# this is snapshot of raw data per process
# including 
WMI::Win32_PerfRawData_PerfProc_Process.find(:all)[0].PercentProcessorTime
# and also the PID


def fill into_this
  a = nil
  WMI::Win32_PerfRawData_PerfProc_Process.find(:all).each{|proc|
    into_this[proc.IDProcess] = proc.PercentProcessorTime.to_i
    a = proc.TimeStamp_Sys100NS
  }
  a
end

# anticipate {123 => 456}

def diff_values first, second
  answer = {}
  for key in first.keys
    if first[key] != second[key]
      answer[key] = first[key] - second[key]
    end
  end
  answer
end

old = {}
ts1 = fill old
sleep 0.1
new = {}
ts2 = fill new
puts (diff_values new, old).inspect
puts new.sort.inspect
puts ts1, ts2