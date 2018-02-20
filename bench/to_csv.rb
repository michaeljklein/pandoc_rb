#!/usr/bin/env ruby

require 'csv'

CSV.open('bench.csv','w'){|csv|File.read('bench.log').lines.map{|x|x.match(/^from: ([^,]+), to: ([^,]+), file: ([^,]+), ([^:]+): \s+(\d+\.\d+) i\/s .*$/)}.compact.sort_by{|x|x[0]}.each{|x|csv<<(x[1,4]<<x[5].to_f)}}
