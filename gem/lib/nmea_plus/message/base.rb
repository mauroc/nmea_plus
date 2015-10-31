

class Class
  # make our own shortcut syntax for message attributes
  def field_reader(name, field_num, formatter=nil)
    if formatter.nil?
      self.class_eval("def #{name};@fields[#{field_num}];end")
    else
      self.class_eval("def #{name};#{formatter}(@fields[#{field_num}]);end")
    end
  end
end


module NMEAPlus

 module Message
   class Base
     attr_accessor :prefix
     attr_reader :payload
     attr_reader :fields
     attr_accessor :checksum
     attr_accessor :interpreted_data_type
     attr_accessor :next_part

     field_reader :data_type, 0, nil

     def original
       "#{prefix}#{payload}*#{checksum}"
     end

     def payload= val
       @payload = val
       @fields = val.split(',', -1)
     end

     def checksum_ok?
       calculated_checksum == checksum
     end

     def calculated_checksum
       "%02x" % payload.each_byte.map{|b| b.ord}.reduce(:^)
     end

     # many messages override these fields
     def total_messages
       1
     end

     # sequence number
     def message_number
       1
     end

     # create a linked list (O(n) implementation; message parts assumed to be < 10) of message parts
     def add_message_part(msg)
       if @next_part.nil?
         @next_part = msg
       else
         @next_part.add_message_part(msg)
       end
     end

     def all_messages_received?
       message_number == 1 && _all_message_parts_chained?(0)
     end

     def _all_message_parts_chained?(highest_contiguous_index)
       mn = message_number # just in case this is expensive to compute
       return false if mn - highest_contiguous_index != 1 # indicating a skip or restart
       return true  if mn == total_messages               # indicating we made it to the end
       return false if @next_part.nil?                    # indicating we're incomplete
       @next_part._all_message_parts_chained?(mn)         # recurse down
     end

     # conversion functions

     # convert DDMM.MMM to single decimal value.
     # sign_letter can be N,S,E,W
     def _degrees_minutes_to_decimal(dm_string, sign_letter = "")
       return nil if dm_string.nil? or dm_string.empty?
       r = /(\d+)(\d{2}\.\d+)/  # (some number of digits) (2 digits for minutes).(decimal minutes)
       m = r.match(dm_string)
       raw = m.values_at(1)[0].to_f + (m.values_at(2)[0].to_f / 60)
       raw *= -1 if !sign_letter.empty? and "SW".include? sign_letter.upcase
       raw
     end

     # convert MM.MMM to single decimal value.
     # sign_letter can be N,S,E,W
     def _minutes_to_decimal(m_string, sign_letter = "")
       return nil if m_string.nil? or m_string.empty?
       r = /(\d+(\.\d+)?)/  # (some number of digits) (2 digits for minutes).(decimal minutes)
       m = r.match(m_string)
       raw = m.values_at(1)[0].to_f
       raw *= -1 if !sign_letter.empty? and "SW".include? sign_letter.upcase
       raw
     end

     # integer or nil
     def _integer(field)
       return nil if field.nil? or field.empty?
       field.to_i
     end

     # float or nil
     def _float(field)
       return nil if field.nil? or field.empty?
       field.to_f
     end

     # string or nil
     def _string(field)
       return nil if field.nil? or field.empty?
       field
     end

     # hex to int or nil
     def _hex_to_integer(field)
       return nil if field.nil? or field.empty?
       field.hex
     end

     # utc time or nil (HHMMSS or HHMMSS.SS)
     def _utctime_hms(field)
       return nil if field.nil? or field.empty?
       re_format = /(\d{2})(\d{2})(\d{2}(\.\d+)?)/
       now = Time.now
       begin
         hms = re_format.match(field)
         Time.new(now.year, now.month, now.day, hms[1].to_i, hms[2].to_i, hms[3].to_f)
       rescue
         nil
       end
     end

   end
 end
end
