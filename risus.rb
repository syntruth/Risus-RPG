=begin rdoc
# Risus RPG Module in Ruby
# Created by Randy Carnahan June, 2009
# Free to Redistribute but please keep this header intact.
#
# See here for distribution details:
#  http://www222.pair.com/sjohn/risus-usage.htm
#
# VERSION:: 1.2

# Change Log::
#   1.0 Initial version.
#   1.1 Added Pumped Dice syntax
#   1.2 Added Funky Dice options
=end

module Risus

  # Generic Risus Error
  class RisusError < Exception
  end

  FunkyDice = [:d6, :d8, :d10, :d12, :d20, :d30]

  class Character
    
    attr :name
    attr :desc
    attr :cliches

    # Takes a Risus character and packs it into a specially
    # formatted string, built upon the +pack+ method of each 
    # cliche.
    def Character.pack(char)
      cliches = []
      char.cliches.keys.each do |k|
        cliches.push(char.cliches[k].pack())
      end
      return "%s;%s;%s" % [char.name, char.desc, cliches.join("|")]
    end

    # Takes a string and unpacks it, create a Character instance from
    # the data contained within.
    def Character.unpack(text)
      data = text.split(/\;/)
      data_len = data.length()
      if data_len < 2
        raise RisusError, "Error unpacking character: #{text}"
      end
      
      char = new(data[0], data[1])

      if data_len >= 3
        data[2].split("|").each do |c|
          char.add_cliche(Cliche.create_from_pack(c))
        end
      end

      return char
    end

    def initialize(name, desc="")
      @name = name
      @desc = desc
      @cliches = {}
    end

    # Adds a cliche to the character.
    # name_or_obj::
    #   Either the name of the cliche or a Cliche object.
    # +value+, +is_double+, and +funky+ are the same as on the
    # Cliche class contructor.
    def add_cliche(name_or_obj, value=1, is_double=false, funky=nil)

      case name_or_obj
      when String
        cliche = Cliche.new(name_or_obj, value, is_double, funky)
      when Cliche
        cliche = name_or_obj
      else
        raise RisusError, "Unknown value for add_cliche: " + 
          "#{name_or_obj} - #{name_or_obj.class}"
      end

      @cliches[cliche.name] = cliche

      return self
    end

    def update_cliche(name_or_sym, value, funky=nil)
      name = Cliche.symbolize_name(name_or_sym.to_s())
      if @cliches.has_key?(name)
        @cliches[name].update(value, funky)
      end
      return self
    end

    def remove_cliche(name)
      return @cliches.delete(Cliche.symbolize_name(name))
      return self
    end

    def to_s
      s = "#{@name}"
      s += "\n#{@desc}" if @desc.any?
      cliches = []
      keys = @cliches.keys.sort {|k1, k2| k1.to_s() <=> k2.to_s() }
      keys.each do |k|
        cliches.push(@cliches[k].to_s())
      end
      s += ("\nCliches: " + cliches.join(", ")) if cliches.any?
      return s
    end

    def pack
      return Character.pack(self)
    end
  end

  # Holds the most important part of a Risus character, the cliche!
  class Cliche
    attr :name
    attr :value
    attr :is_double
    attr :funky

    # Human to symbol for a cliche's name.    
    def Cliche.symbolize_name(name)
      return name.downcase.gsub(/\s+/, "_").to_sym()
    end

    # Symbol to human for a cliche's name.
    def Cliche.humanize_name(sym)
      return sym.to_s.split(/_/).collect { |s|
        s.capitalize
      }.join(" ")
    end

    # Packs the clich into a string.
    def Cliche.pack(cliche)
      double = cliche.is_double ? 1 : 0
      return [cliche.name, cliche.value, double, cliche.funky.to_s()].join(":")
    end

    # Takes a string and parses it, returning an array or raises 
    # an exception otherwise.
    def Cliche.unpack(text)
      begin
        name, value, is_double, funky = text.split(/:/)
      rescue Exception
        raise RisusError, "Trouble unpacking Cliche: #{text}"
      end
      return [name, value, is_double.to_i.zero? ? false : true, funky.to_sym()]
    end

    # Takes a string, unpacks it, and then creates a Cliche instance
    # from the returned data.
    def Cliche.create_from_pack(text)
      name, value, is_double, funky = Cliche.unpack(text)
      return new(name, value, is_double, funky)
    end

    # Constructor for the Cliche.
    #
    # +name+:: The name of the cliche, should be a string.
    # +value+:: How many dice in the cliche, should be an integer.
    # +is_double+:: Boolean value on if this cliche can be double pumped.
    # +funky+:: Should be a dice-value symbol from the +FunkyDice+ constant.
    def initialize(name, value, is_double=false, funky=nil)
      @name = Cliche.symbolize_name(name)
      @value = value
      @is_double = is_double
      @funky = funky.nil? ? :d6 : funky
    end

    # Updates the +value+ and +funky+ values. +funky+ can be omitted.
    def update(value, funky=nil)
      @value = value
      @funky = funky.nil? ? :d6 : funky
    end

    def is_funky?
      return true if @funky != :d6
    end

    def dice_string
      return @value.to_s() + @funky.to_s()
    end

    def to_s
      name = Cliche.humanize_name(@name)
      value = @value.to_s()
      value += @funky.to_s() if self.is_funky?
      return "%s[%s]" % [name, value] if @is_double
      return "%s(%s)" % [name, value]
    end

    # Wrapper for +Cliche.pack+
    def pack
      return Cliche.pack(self)
    end

  # End Cliche Class
  end

end
