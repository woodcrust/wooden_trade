module TradeWoodenApi
  class Core

    attr_accessor :bot, :binance, :cex, :poloniex, :huobi

    def initialize(bot)
      binance  = TradeWoodenApi.binance
      cex      = TradeWoodenApi.cex
      poloniex = TradeWoodenApi.poloniex
      huobi    = TradeWoodenApi.huobi

      self.binance  = TradeWoodenApi::Binance::Rest.new(binance[:api_url], binance[:api_key], binance[:secret])
      self.cex      = TradeWoodenApi::Cex::Rest.new(cex[:id], cex[:api_url], cex[:api_key], cex[:secret])
      self.poloniex = TradeWoodenApi::Poloniex::Rest.new(poloniex[:api_url], poloniex[:api_key], poloniex[:secret])
      self.huobi    = TradeWoodenApi::Huobi::Rest.new(huobi[:api_url])
      self.bot = bot
    end

    def call
      user = TradeWoodenApi.telegram_ids.first
      loop do
        TradeWoodenApi.pairs.each do |main_symbol, slave_symbols|
          slave_symbols.each do |symbol|
            b = binance.get_pair_price(symbol, main_symbol).to_f
            p = poloniex.get_pair_price(symbol, main_symbol).to_f
            c = cex.get_pair_price(symbol, main_symbol).to_f
            h = huobi.get_pair_price(symbol, main_symbol).to_f
            
            res = {
              b => 'binance',
              p => 'poloniex',
              c => 'cex',
              h => 'huobi'
            }

            a = [b,p,c,h].select{ |val| val > 0 }.sort
            if a.first <= 0
              sleep 2
              next
            else
              r = (a.last * 100)/a.first - 100
            end

            text = "#{symbol}/#{main_symbol}%0A"\
            "binance - #{b}%0A"\
            "poloniex - #{p}%0A"\
            "cex - #{c}%0A"\
            "huobi - #{h}%0A"\
            "----------------------------%0A"\
            "min: #{res[a.first]} < max: #{res[a.last]}%0A"\
            "max difference #{r.round(5)} %%0A"\
            "----------------------------"
                        
            TradeWoodenApi.telegram_ids.each do |user|
              bot.send_message(user, text)
            end if r >= TradeWoodenApi.signal_percent
            sleep 2
          end
        end
      end
    end
  end
end