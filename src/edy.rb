# coding: utf-8

require 'date'

java_import 'net.kazzz.util.Util'

class Edy

  attr_reader :title
  def initialize(data)
    @data = data
    @title = 'Edy'
  end

  def to_string
    <<-EOF.gsub /^\s+/, ""
      区分: #{category}
      連番： #{sequence}
      日時： #{datetime}
      金額： #{to_currency(amount)}
      残高： #{to_currency(balance)}
    EOF
  end

  def category
    case to_hex_string(@data[0])
    when '0x02'; 'チャージ'
    when '0x04'; 'Edyギフト'
    when '0x20'; '支払い'
    else; '???'
    end
  end

  def sequence
    Util.toInt(@data[1], @data[2], @data[3]).to_s
  end

  def datetime
    dt10 = Util.toInt(@data[4], @data[5], @data[6], @data[7])

    # 2進数に直したときの、上位15bitが日付、下位17bitが時刻
    # 上記は10進数なので、2進数へと変換する
    dt2 = dt10.to_s(2).to_i(2)

    # 日付の算出
    # 先頭から15bit残すので、右にある17bitをシフトして消す
    elapsed_days = dt2 >> 17
    # elapsed_days = dt2.to_i(2) >> 17

    # 時刻の算出
    # 後ろから17bitだけを残すので、不要なbitを消すために、論理積を取る
    elapsed_time = dt2 & 0b00000000000000011111111111111111

    # 2000/01/01からの経過日時の算出
    d = (Date.new 2000, 1, 1) + elapsed_days
    dt = Time.local(d.year, d.month, d.day, 0, 0, 0, 0) + elapsed_time
    dt.strftime('%Y/%m/%d %H:%m:%S')
  end

  def amount
    Util.toInt(@data[8], @data[9], @data[10], @data[11])
  end

  def balance
    Util.toInt(@data[12], @data[13], @data[14], @data[15])
  end

  def to_hex_string(byte)
    "%#02x" % (byte & 0xff)
  end

  def to_currency(value)
    '￥' + value.to_s.gsub(/(?<=\d)(?=(?:\d{3})+(?!\d))/, ',')
  end
end