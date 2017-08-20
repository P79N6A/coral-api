#encoding: utf-8
$LOAD_PATH << File.join(File.dirname(__FILE__), '../jar')
require 'java'
require 'jxl.jar'
require 'pathname'
require 'utility'
require 'logger'

def jxl
  Java::Jxl
end

import jxl.Workbook
import jxl.Sheet
import jxl.Cell
module FileOperation
  module Excel
    #有表头但不包含表头
    def rows_noheader(f,idxorsheet=0)
      begin
        data = {}
        workbook = Workbook.getWorkbook(java.io.File.new(f))
        sheet = workbook.getSheet(idxorsheet)
        rownum = sheet.getRows                              #获取行数
        if rownum <= 1
           raise 'Excel error! 2 rows at least, please check it first!'
        else
            0.upto(rownum-1) do |i|
              rowcontent = []
              cells =  sheet.getRow(i)
              cells.each{|cell|rowcontent << (cell.getContents.empty? ? "":cell.getContents.encode!('utf-8'))}
              data[i] = rowcontent
            end
        end
        data.delete(0)
        data
      rescue StandardError => e
        puts "FileOperation::Excel::"+__method__.to_s()+": "+e.to_s
        Clog.to_log("FileOperation::Excel::"+__method__.to_s()+": "+e.to_s)
      end
    end

    #有表头包含表头
    def rows_with_header(f,idxorsheet=0)
      begin
        data = {}
        workbook = Workbook.getWorkbook(java.io.File.new(f))
        sheet = workbook.getSheet(idxorsheet)
        rownum = sheet.getRows                              #获取行数

        if rownum <= 1
          raise 'Excel error! 2 rows at least, please check it first!'
        else
          rowheader = []
          header = sheet.getRow(0)
          header.each do |cell|
            if !cell.getContents.empty?
              rowheader << cell.getContents.encode!('utf-8')
            else
              raise "Header cell can't be empty!"
            end
          end
          1.upto(rownum-1) do |i|
            rowcontent = []
            cells =  sheet.getRow(i)
            cells.each{|cell| rowcontent << (cell.getContents.empty? ? "":cell.getContents.encode!('utf-8'))}
            alist = rowheader.zip(rowcontent)
            data[i] = Hash[*alist.flatten].tap{|h| h.each{|k,v| h[k] = "" if (v.nil?) }}
          end
        end
        data
      rescue StandardError => e
        puts "FileOperation::Excel::"+__method__.to_s()+": "+e.to_s
        Clog.to_log("FileOperation::Excel::"+__method__.to_s()+": "+e.to_s)
      end
    end

    #无表头仅数据
    def rows_onlydata(f,idxorsheet=0)
      begin
        data = {}
        workbook = Workbook.getWorkbook(java.io.File.new(f))
        sheet = workbook.getSheet(idxorsheet)
        rownum = sheet.getRows                              #获取行数
        if rownum == 0
          raise 'Excel error! 1 rows at least, please check it first!'
        else
          0.upto(rownum-1) do |i|
            rowcontent = []
            cells =  sheet.getRow(i)
            cells.each{|cell|rowcontent << cell.getContents.encode!('utf-8') if !cell.getContents.empty? }
            data[i+1] = rowcontent
          end
        end
        data
      rescue StandardError => e
        puts "FileOperation::Excel::"+__method__.to_s()+": "+e.to_s
        Clog.to_log("FileOperation::Excel::"+__method__.to_s()+": "+e.to_s)
      end
    end
  end

  #end of excel class

  module Clog
    def self.createfile(path)
      begin
        if !File.exist?(path)
          File.new(path,"w")
        else
          File.new(path,"a")
        end
      rescue StandardError=>e
        puts e.to_s
      end
    end

    def self.to_log(content)
      begin
        logfile = File.new(getrootpath+"log/log_"+Time.now.strftime("%Y-%m-%d")+".log","a+")
        logfile.write(Time.now.strftime("%Y-%m-%d %H:%M:%S")+"   "+content+"\r\n")
      rescue StandardError=>e
        puts e.to_s
      end
    end

  end

  # end of Clog module

  class Flog
    include FileOperation
    def initialize()
      begin
        if !File.exist?(getrootpath+"log/fwlog_"+Time.now.strftime("%Y-%m-%d")+".log")
          @logger = Logger.new(getrootpath+"log/fwlog_"+Time.now.strftime("%Y-%m-%d")+".log")
        else
          @logger = Logger.new(getrootpath+"log/fwlog_"+Time.now.strftime("%Y-%m-%d")+".log",File::APPEND)
        end
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @logger.formatter = proc {|severitylabel,datetime,progname,msg|"[#{severitylabel}]  #{datetime.strftime("%Y-%m-%d %H:%M:%S")} :#{progname}: #{msg}\n"}

    end

    def debug(progname,msg)
      begin
        @logger.add(Logger::DEBUG,msg,progname)
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def info(progname,msg)
      begin
        @logger.add(Logger::INFO,msg,progname)
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end
    def warn(progname,msg)
      begin
        @logger.add(Logger::WARN,msg,progname)
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end
    def error(progname,msg)
      begin
        @logger.add(Logger::ERROR,msg,progname)
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end
    def fatal(progname,msg)
      begin
        @logger.add(Logger::FATAL,msg,progname)
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end
  end
end

