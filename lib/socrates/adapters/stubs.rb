module Socrates
  module Adapters
    Response = Struct.new(:members)
    User     = Struct.new(:id, :name, :profile)
    Profile  = Struct.new(:first_name, :last_name, :email)
  end
end
