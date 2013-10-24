# coding: utf-8

java_import 'net.kazzz.felica.lib.FeliCaLib'

class FeliCaLib
  # システムコード
  SYSTEMCODE_KURURU = '0x8D3F'.to_i(16)

  # サービスコード
  # 参照：　http://jennychan.web.fc2.com/format/edy.html
  SERVICE_EDY_HISTORY = '0x170F'.to_i(16)
  SERVICE_KURURU_HISTORY = '0x000F'.to_i(16)
end