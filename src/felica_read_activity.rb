# coding: utf-8

require 'ruboto/widget'
require 'ruboto/util/toast'
require 'suica'
require 'edy'
require 'kururu'
require 'felica_lib'
require 'felica_tag'
require 'util'

ruboto_import_widgets :LinearLayout, :ScrollView, :TextView, :Button

java_import 'android.nfc.NfcAdapter'
java_import 'android.nfc.NfcManager'
java_import 'android.nfc.tech.NfcF'
java_import 'android.content.Intent'
java_import 'android.app.PendingIntent'
java_import 'android.util.Log'

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

    dump = read_felica(intent)

    if dump.nil?
      toast '不明なFeliCaが読み込まれたため、処理できませんでした。'
    else
      @history.text = dump[:history]
      @balance.text = '現在の残高： ￥' + Util.add_thousand_separator(dump[:balance].to_s)

      toast '読み込みが完了しました。'
    end
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
    # こちらも onResume 同様、nilになっていることがあるため、nilチェックを追加
    @adapter.disableForegroundDispatch(self) if isFinishing && !@adapter.nil?
  end


  def create_pending_intent
    p = getPackageName
    c = self.java_class.name
    i = Intent.new
    # AndroidManifestにlaunchModeを記載したので、ここではフラグの指定は不要みたい
    i.setClassName(p, c)

    PendingIntent.getActivity(self, 0, i, 0)
  end



  def read_felica(intent)
    tag = intent.getParcelableExtra(NfcAdapter::EXTRA_TAG);
    codes = FeliCaTag.new_instance(tag).getSystemCodeList

    # 最初に一致したシステムコードのデータを読み込む
    codes.each do |code|
      system_code = Util.getHexString(code.getBytes)

      # 今後のデバッグを考え、読み込んだシステムコードをログに出力しておく
      Log.v 'ruboto_felica_read', "システムコード： #{system_code}"

      case system_code
      when Util.to_system_code_hex_string(FeliCaLib::SYSTEMCODE_SUICA)
        return dump_history(tag,
                            FeliCaLib::SYSTEMCODE_SUICA,
                            FeliCaLib::SERVICE_SUICA_HISTORY,
                           ->(block_data, activity){ Suica::History.new(block_data, activity) } )

      when Util.to_system_code_hex_string(FeliCaLib::SYSTEMCODE_EDY)
        return dump_history(tag,
                            FeliCaLib::SYSTEMCODE_EDY,
                            FeliCaLib::SERVICE_EDY_HISTORY,
                            ->(block_data, activity){ Edy.new(block_data) } )

      when Util.to_system_code_hex_string(FeliCaLib::SYSTEMCODE_KURURU)
        return dump_history(tag,
                            FeliCaLib::SYSTEMCODE_KURURU,
                            FeliCaLib::SERVICE_KURURU_HISTORY,
                            ->(block_data, activity){ Kururu.new(block_data) } )
      end
    end

    # ここまで来た場合、どのシステムコードも一致しなかったので、nilを返しておく
    nil
  end


  def dump_history(tag, system_code, service_code, func)
    felica_tag = FeliCaTag.new(tag)
    felica_tag.polling(system_code)

    sc = FeliCaLib::ServiceCode.new(service_code)
    addr = 0
    result = felica_tag.readWithoutEncryption(sc, addr)

    history = ''
    while !result.nil? && result.getStatusFlag1 == 0
      target = func.call(result.getBlockData, self)

      history += <<-EOF.gsub /^\s+/, ""
        #{target.title} 履歴 No. #{(addr + 1)}
        ---------
        #{target.to_s}
        ---------------------------------------

      EOF

      balance = target.balance if balance.nil?
      addr += 1

      begin
        result = felica_tag.readWithoutEncryption(sc, addr)
      rescue
        history += <<-EOF.gsub /^\s+/, ""
        ---------------------------------------
        読込が中断されました
        ---------------------------------------
        EOF

        return {history: history, balance: balance}
      end
    end

    return {history: history, balance: balance}
  end
end