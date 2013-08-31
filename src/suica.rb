java_import 'net.kazzz.felica.suica.Suica'

# Javaのクラス名を指定して、あとはメソッドを書いていけば、動的に拡張できる
class Suica::History
  # toStringメソッドは、JRubyが自動的に to_string メソッドへと変換してくれるので、実装しなくてよい

  def title
    'Suica'
  end

  def balance
    b = self.getBalance
    b.to_s.gsub(/(?<=\d)(?=(?:\d{3})+(?!\d))/, ',')
  end
end