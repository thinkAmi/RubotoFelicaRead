# coding: utf-8

java_import 'net.kazzz.felica.FeliCaTag'
java_import 'net.kazzz.felica.lib.FeliCaLib'


class FeliCaTag

  field_writer :idm

  def self.new_instance(tag)
    f = FeliCaTag.new(tag)
    f.idm = FeliCaLib::IDm.new(tag.getId)
    f
  end
end