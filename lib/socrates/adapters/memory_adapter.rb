class MemoryAdapter
  CLIENT_ID = "MEMORY"

  attr_reader :history

  def initialize
    @history = []
  end

  def client_id_from_context(_context)
    CLIENT_ID
  end

  def send_message(message, _context)
    @history << message
  end

  def last_message
    @history.last
  end
end
