# coding: utf-8

require 'util'

class Kururu

  attr_reader :title
  def initialize(data)
    @data = data
    @title = 'Kururu'
  end


  def to_s
    # 日付が初期値の場合、まだ履歴が存在していないと考えて、何も出力しない
    return '' if usage_date == '0000/00/00'

    # 機番・場所・種別・会社・割引は想像
    <<-EOF.gsub /^\s+/, ""
      日付: #{usage_date}
      機番: #{machine}
      乗車時刻: #{boarding_time}
      乗車停留所: #{boarding_stop}
      降車時刻: #{alighting_time}
      降車停留所: #{alighting_stop}
      場所: #{place}
      種別: #{category}
      会社: #{company}
      割引: #{discount}
      残高： ￥#{Util.add_thousand_separator(balance)}
    EOF
  end


  def usage_date
    # 日付: 16bitを、7bit-4bit-5bitで区切っている
    b = Util.getBinString(@data[0]) + Util.getBinString(@data[1])
    yy = b[0, 7].to_i(2)
    yyyy = (yy == 0) ? yy : yy + 2000
    mm = b[7, 4].to_i(2)
    dd = b[11, 5].to_i(2)

    "%04d/%02d/%02d" % ([yyyy, mm, dd])
  end


  def alighting_time
    usage_time(@data[2])
  end


  def machine
    Util.toInt(@data[3], @data[4])
  end


  def boarding_time
    usage_time(@data[5])
  end


  def boarding_stop
    Util.toInt(@data[6], @data[7])
  end


  def alighting_stop
    Util.toInt(@data[8], @data[9])
  end


  def place
    b = Util.high_order_4bit(@data[10])
    case b
    when '0101'
      "車内 (#{b})"
    when '0111'
      "営業所 (#{b})"
    when '1110'
      "券売機 (#{b})"
    else
      "不明 (#{b})"
    end
  end


  def category
    b = Util.low_order_4bit(@data[10])
    case b
    when '0000'
      "入金 (#{b})"
    when '0010'
      "支払 (#{b})"
    else
      "不明 (#{b})"
    end
  end


  def company
    b = Util.high_order_4bit(@data[11])
    case b
    when '0001'
      "長電バス (#{b})"
    when '0011'
      "アルピコバス (#{b})"
    else
      "不明 (#{b})"
    end
  end


  def discount
    b = Util.low_order_4bit(@data[11])
    case b
    when '0000'
      "入金 (#{b})"
    when '0001'
      "なし (#{b})"
    else
      "不明 (#{b})"
    end
  end


  def balance
    Util.toInt(@data[12], @data[13], @data[14], @data[15])
  end


  def usage_time(byte)
    # 時刻は10で割ったものが格納されているため、10倍して復元する
    t = Util.toInt(byte)
    hhmm = (t * 10).divmod(60)

    "%02d:%02d:00" % ([hhmm[0], hhmm[1]])
  end
end