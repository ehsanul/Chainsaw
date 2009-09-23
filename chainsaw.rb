require 'yaml'

class Chain
  class << self
    attr_reader :last_date, :length, :chain
    
    def create( chain, file = 'chains.yaml' )
      @chain = chain; @file = file; @data ||= {}
      @data.merge!( {chain => { 'last_date' => @last_date = Date.today - 1, 'length' => @length = 0 }} )
      update_last_chain(chain)
      File.open( file, 'w' ) { |f| f.write @data.to_yaml }
    end
    
    def update_last_chain(chain)
      @data['last_chain'] = @data[chain].merge({ 'chain' => chain })
    end
    
    def open( chain = 'last_chain', file = 'chains.yaml' )
      @file = file
      if File.exists? file
        File.open( file, 'r' ) { |f| @data = YAML::load(f) }
        # Assume the file was properly formatted, and @data is the expect hash
        @last_date, @length  = @data[chain]['last_date'], @data[chain]['length']
        @chain = (chain == 'last_chain') ? @data[chain]['chain'] : chain
      else return false
      end
    end
    
    def list
      @data.keys - ['last_chain']
    end
    
    def add
      if Date.today == @last_date then return false
      else
        @data[@chain] = { 'length' => @length += 1, 'last_date' => @last_date += 1 }
        update_last_chain(@chain)
        File.open( @file, 'w' ) { |f| f.write @data.to_yaml }
      end
    end
    
    def undo_add
      if @length == 0 then return false
      else
        @data[@chain] = { 'length' => @length -= 1, 'last_date' => @last_date -= 1 }
        update_last_chain(@chain)
        File.open( @file, 'w' ) { |f| f.write @data.to_yaml }
      end
    end
    
    def broken?
      Date.today > @last_date + 1
    end
  end
end

Shoes.app(:title => "Chainsaw", :width => 500) do 

  def checkmark
    image "sketchy checkmark.jpg", :width => 84, :height => 84
  end
  def xmark
    image "sketchy xmark.jpg", :width => 84, :height => 84
  end
  
  def create_chain
    chain = ask "What do you want to call your chain?" 
    Chain.create(chain) if chain
  end
  
  def update_gui
    update_buttons
    @title.replace Chain.chain
    update_view
  end
  
  def update_buttons
    # Buttons will change based on state, when I get to it
  end
  
  def update_view
    @view.clear do
      if Chain.broken?
        para "Oh no! You broke the chain! It lasted for #{Chain.length} days..\n\n"
        Chain.length.times { xmark }
      else
        para "Your chain is #{Chain.length} days long! Woooot!!\n\n"
        Chain.length.times { checkmark }
      end
    end
  end
  
  background white
  
  @buttons = flow(:width => 1.0) do
    button("New") do
      create_chain
      update_gui
    end
    button("Open") do
      window(:width => 100, :height => 300) do
        Chain.list.each do |chain|
          button(chain) { Chain.open(chain); owner.update_gui; close }
        end
      end
    end
    button("Chain") { update_view if Chain.add }
    button("Unchain") { update_view if Chain.undo_add }
  end
  
  create_chain unless Chain.open
  @title = title Chain.chain
  @view = flow(:width => 1.0, :left => 5)
  update_gui
  every(60) { update_gui }
  
end
