require 'frubygems' if $0 == __FILE__ && RUBY_VERSION < '1.9'
require 'sane'
require 'ruby-wmi'
require 'benchmark'


# take a snapshot of the processes' status
# could be more efficient by selecting just what we wanted, I suppose
def fill into_this
  all = WMI::Win32_PerfRawData_PerfProc_Process.find(:all).each{|proc|
    into_this[proc.IDProcess] = {:processor => proc.PercentProcessorTime.to_i, :data => proc.IODataBytesPerSec.to_i}
  }
  return all[0].TimeStamp_Sys100NS.to_i # these are all the same
end

#
# compare two snapshots
#
def diff_values first, second, time_diff, what_to_calculate
  answer = {}
  for key in first.keys
    if first[key] != second[key] # sometimes they stay the same
      begin
        answer[key] = (first[key][what_to_calculate] - second[key][what_to_calculate]).to_f/time_diff
        if what_to_calculate == :data
            answer[key] *= 10_000_000 # strip off the 100_ns aspect
        else
            answer[key] *= 100 # percentages come as 0.99 -- we want 99 to mean 99% of one core
        end

      rescue
        # sometimes the values are nil
        # ignore I suppose
      end
    end
  end
  answer
end

loop {
  print '.' if $VERBOSE
  STDOUT.flush
  old = {}

  ts1 = fill old
  $VERBOSE ? sleep( 1 ) : sleep( 3 )
  new = {}
  ts2 = fill new

  for value in [:processor, :data]
    sorted = diff_values( new, old, ts2 - ts1, value ) # give use "just data" or not
    puts value, sorted.inspect if $VERBOSE
    violated = []

    sorted.each{|pid, reading|

      if value == :processor
        max = 97 # > 97% of one core -> penalt!
      elsif value == :data
        max = 1_000_000 # more than 1 MB/s -> penalt!
      end

      if reading > max && pid != 0 # using a full core (100) or more...
        violated << pid
        proc = WMI::Win32_Process.find(:first,  :conditions => {:ProcessId => pid.to_i})
        if proc.Priority > 4 # appears that 7 or 8 here mean normal prio...
          proc.SetPriority 64 # set it to low priority
          puts "violated!", pid, value, reading, "was greater than", max
        end
      end
    }
  end
}
