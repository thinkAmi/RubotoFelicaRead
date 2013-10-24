# coding: utf-8

java_import 'net.kazzz.util.Util'

class Util
  def self.add_thousand_separator(value)
    value.to_s.gsub(/(?<=\d)(?=(?:\d{3})+(?!\d))/, ',')
  end

  def self.to_system_code_hex_string(hex)
    # 後ろ4bitがシステムコードの文字列(先頭4bitはオールゼロ)
    # net.kazzz.util.Utilの同じクラス内なので、 Java側のメソッドを使う場合でも Util. というプレフィックスはいらない
    getHexString(toBytes(hex))[-4,4]
  end

  def self.high_order_4bit(byte)
    getBinString(byte)[0, 4]
  end

  def self.low_order_4bit(byte)
    getBinString(byte)[-4, 4]
  end
end