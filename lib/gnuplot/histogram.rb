require 'gnuplot'
require "gnuplot/histogram/version"

module Gnuplot
  module Histogram
    # 1D histogram
    class Hist
      def initialize

      end
    end

    # 2D histogram
    class Hist2D
      attr_accessor :xdata, :ydata,
        :title, :xlabel, :ylabel, :cblabel,
        :binres_x, :binres_y,
        :interval_x, :interval_y,
        :dx, :dy, :x, :y, 
        :max_x, :max_y,
        :min_x, :min_y,
        :logscale, :withmedian, :withquartile

      def initialize(xdata, ydata, bin_x=100, bin_y=100)

        @binres_x = bin_x
        @binres_y = bin_y

        @xdata = xdata
        @ydata = ydata

        @max_x = xdata.max.to_f
        @min_x = xdata.min.to_f
        @max_y = ydata.max.to_f
        @min_y = ydata.min.to_f

        @max_x = 999.0 if @max_x.infinite?
        @max_y = 999.0 if @max_y.infinite?
        @min_x = -999.0 if @min_x.infinite?
        @min_y = -999.0 if @min_y.infinite?

        @logscale = false
        @withmedian = false
        @withquartile = false
      end

      def plot(outfilepath='none')
        @interval_x = ((@max_x - @min_x).to_f / @binres_x).to_f
        @interval_y = ((@max_y - @min_y).to_f / @binres_y).to_f

        @dx = @interval_x / 2.0
        @dy = @interval_y / 2.0

        @x = []
        @y = []

        @binres_x.times do |i|
          @x.push(@min_x + @interval_x * (i + 1).to_f - @dx)
        end
        @binres_y.times do |i|
          @y.push(@min_y + @interval_y * (i + 1).to_f - @dy)
        end

        hist = Array.new(@binres_x).map{Array.new(@binres_y, 0)}
        @binres_x.times do |ix|
          insidebin_x_index = @xdata.each_with_index.select {|a|
            a[0] >= (@x[ix]) and a[0] < (@x[ix] + @interval_x)
          }.map{|a| a[1]}
          @binres_y.times do |iy|
            insidebin_y_index = @ydata.each_with_index.select {|a|
              a[0] >= (@y[iy]) and a[0] < (@y[iy] + @interval_y)
            }.map{|a| a[1]}
            hist[ix][iy] = (insidebin_x_index & insidebin_y_index).length
          end
        end

        Gnuplot.open do |gp|
          SPlot.new(gp) do |plot|
            case outfilepath
            when /^none$/
              plot.terminal 'x11'
            when /\.tex$/
              plot.terminal "tikz"
              plot.output File.expand_path(outfilepath)
            when /\.pdf$/
              plot.terminal "pdf"
              plot.output File.expand_path(outfilepath)
            when /\.png$/
              plot.terminal "pngcairo font 'Helvetica, 22' size 960,720"
              plot.output File.expand_path(outfilepath)
            else
              STDERR.puts "Error: unknown filetype"
              exit
            end

            plot.title @title

            plot.xlabel @xlabel
            plot.ylabel @ylabel
            plot.cblabel @cblabel

            plot.set "datafile missing \"Infinity\""

            plot.set "key off"

            plot.set "view map"
            plot.set "size square"

            plot.xrange "[#{@min_x}:#{@max_x}]"
            plot.yrange "[#{@min_y}:#{@max_y}]"

            if @logscale 
              plot.cbrange "[1:#{hist.flatten.max}]"
              plot.set "logscale cb"
            else
              plot.cbrange "[0:#{hist.flatten.max}]"
            end

            plot.set "palette defined ( 0 '#000090', 1 '#000fff', 2 '#0090ff', 3 '#0fffee', 4 '#90ff70', 5 '#ffee00', 6 '#ff7000', 7 '#ee0000', 8 '#7f0000')"

            plot.data <<
            Gnuplot::DataSet.new([@x, @y, hist]) do |ds|
              ds.with = 'image pixels'
            end
          end
        end
      end
    end
  end
end

