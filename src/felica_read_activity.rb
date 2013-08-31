# coding: utf-8

require 'ruboto/widget'
require 'ruboto/util/toast'
require 'suica'
require 'edy'
require 'felica_lib'

ruboto_import_widgets :LinearLayout, :ScrollView, :TextView, :Button

java_import 'net.kazzz.felica.FeliCaTag'
java_import 'net.kazzz.felica.lib.FeliCaLib'
java_import 'net.kazzz.felica.suica.Suica'
java_import 'android.nfc.NfcAdapter'
java_import 'android.nfc.NfcManager'
java_import 'android.nfc.tech.NfcF'
java_import 'android.content.Intent'
java_import 'android.app.PendingIntent'


class FelicaReadActivity
  def onCreate(bundle)
    super

    @main = linear_layout orientation: :vertical do
            @balance = text_view text: 'Felicaを読んで下さい', text_size: 36
            text_view text: '-' * 60
            scroll_view do
              linear_layout orientation: :vertical do
                @history = text_view text: ''
              end
            end
          end
    self.content_view = @main

    # フォアグラウンド・ディスパッチの準備
    @adapter = NfcAdapter.getDefaultAdapter(self)
  end


  def onNewIntent(intent)
    super

    a = intent.getAction
    return unless a == NfcAdapter::ACTION_TECH_DISCOVERED ||
                  a == NfcAdapter::ACTION_TAG_DISCOVERED

    toast '読み込みを開始します'

    # Suicaのシステムコードかどうかで、Suica/Edyの判定をしている(手抜き...)
    tag = intent.getParcelableExtra(NfcAdapter::EXTRA_TAG);
    case to_system_code(NfcF.get(tag).getSystemCode)
    when FeliCaLib::SYSTEMCODE_SUICA
      h, b = dump_history(tag,
                          FeliCaLib::SYSTEMCODE_SUICA,
                          FeliCaLib::SERVICE_SUICA_HISTORY,
                          ->(block_data, activity){ Suica::History.new(block_data, activity) } )

    else
      h, b = dump_history(tag,
                          FeliCaLib::SYSTEMCODE_EDY,
                          FeliCaLib::SERVICE_EDY_HISTORY,
                          ->(block_data, activity){ Edy.new(block_data) } )
    end

    @history.text = h
    @balance.text = '現在の残高： ￥' + b.to_s.gsub(/(?<=\d)(?=(?:\d{3})+(?!\d))/, ',')

    toast '読み込みが完了しました。'
  end


  def onResume
    super

    # 本来なら後者の条件だけで良いはずだが、なぜかインスタンス変数がnilになっているときもあるので、nilチェックを追加
    if @adapter.nil? || !@adapter.isEnabled
      toast 'NFCが無効になっています。'
      finish
      return
    end

    pi = create_pending_intent
    # フォアグラウンド・ディスパッチで反応するのは、FeliCaだけにする
    t = [[NfcF.java_class.name]]
    @adapter.enableForegroundDispatch(self, pi, nil, t)
  end


  def onPause
    super
    @adapter.disableForegroundDispatch(self) if isFinishing
  end

  def create_pending_intent
    p = getPackageName
    c = self.java_class.name
    i = Intent.new
    # AndroidManifestにlaunchModeを記載したので、ここではフラグの指定は不要みたい
    i.setClassName(p, c)

    PendingIntent.getActivity(self, 0, i, 0)
  end


  def to_system_code(bytes)
    bytes.nil? ? '' : bytes.map{ |byte| "%02X" % (byte & 0xff) }.join.to_i
  end


  def dump_history(tag, system_code, service_code, func)
    felica_tag = FeliCaTag.new(tag)
    felica_tag.polling(system_code)

    sc = FeliCaLib::ServiceCode.new(service_code)
    addr = 0
    result = felica_tag.readWithoutEncryption(sc, addr)

    dump = ''
    while !result.nil? && result.getStatusFlag1 == 0
      target = func.call(result.getBlockData, self)

      dump += <<-EOF.gsub /^\s+/, ""
        #{target.title} 履歴 No. #{(addr + 1).to_s}
        ---------
        #{target.to_string}
        ---------------------------------------

      EOF

      balance = target.balance if balance.nil?
      addr += 1

      begin
        result = felica_tag.readWithoutEncryption(sc, addr)
      rescue
        dump += <<-EOF.gsub /^\s+/, ""
        ---------------------------------------
        読込が中断されました
        ---------------------------------------
        EOF

        return dump, balance
      end
    end

    return dump, balance
  end
end