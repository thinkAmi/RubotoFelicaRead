# coding: utf-8

require 'util'
java_import 'net.kazzz.felica.suica.Suica'

# Javaのクラス名を指定して、あとはメソッドを書いていけば、動的に拡張できる
# JRuby側で to_s した場合、自動的に toString メソッドが呼び出されるので、 to_s は特に実装しない
class Suica::History

  def title
    'Suica'
  end


  def balance
    Util.add_thousand_separator(getBalance)
  end
end