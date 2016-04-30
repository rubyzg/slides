# Ruby Struct class

# Using bare Struct {{{

# Struct returns a class (!!)
struct = Struct.new(:id, :name)  # => #<Class:0x007f89cc003950>
struct.is_a? Class               # => true

# Instantiating a new struct class
instance = struct.new(123, "John Wayne")  # => #<struct id=123, name="John Wayne">
instance.id                               # => 123
instance.name                             # => "John Wayne"

instance.name = "Clint Eastwood"  # => "Clint Eastwood"
instance.name                     # => "Clint Eastwood"

instance[:name] = "Charles Bronson"  # => "Charles Bronson"
instance.name                        # => "Charles Bronson"

# Thoughts:
# - yea.. but why?
# - instantiating twice is un-Ruby

# }}}
# Subclassing struct {{{

# ** Ruby idiom **
class Cowboy < Struct.new(:id, :name)
  def says
    "My id is more than #{id}"         # => "My id is more than Infinity"
  end
end

chuck = Cowboy.new(234, "Chuck Norris")  # => #<struct Cowboy id=234, name="Chuck Norris">
chuck.id = Float::INFINITY               # => Infinity
chuck.says                               # => "My id is more than Infinity"

# the equivalent class

class Cowboy2

  attr_accessor :id, :name  # => nil

  def initialize(id, name)
    @id = id
    @name = name
  end

  def says
    "My id is more than #{id}"
  end

end


# Ok.. but still, why? Arguments:

# - elegant and succinct, accessor defined in a single place
# - struct states *nothing* happens in an initializer
# - faster than writing the initializer
# - it's an idiom you'll see in many, many gems
# - using it feels good, try it

# }}}
# Better usage with a constant {{{

class Gun < Struct.new(:name, :size)
  # ...
end

# Downside: anonymous class in ancestor chain
Gun.ancestors  # => [Gun, #<Class:0x007f89cc001920>, Struct, Enumerable, Object, JSON::Ext::Generator::GeneratorMethods::Object, Kernel, BasicObject]

# Solution:
Pistol = Struct.new(:bullets) do  # => Struct
  def shoot
    "bang"
  end
end                               # => Pistol

Pistol.ancestors  # => [Pistol, Struct, Enumerable, Object, JSON::Ext::Generator::GeneratorMethods::Object, Kernel, BasicObject]

# What really happens there?

struct = Struct.new(:foo) do  # => Struct
  def something
  end
end                           # => #<Class:0x007f89cc000520>

struct.is_a? Class  # => true
struct.name         # => nil

# Interesting (assignment happens on the object on the right)
Something = struct  # => Something
struct.name         # => "Something"

# }}}
# Is it really better? {{{

# Is using better syntax really better?
Rifle = Struct.new(:model) do  # => Struct
  def shoot
    "ka-bang"
  end
end                            # => Rifle

# Downsides:
# - a lot of devs don't know what it is
# - editor issues (ctags doesn't recognize new class)
# - not pretty, defining methods in a block?

# Suggestion:
# - "improved" syntax for ruby gems
# - "classic" syntax for your application code

# }}}

# vim: fdm=marker
