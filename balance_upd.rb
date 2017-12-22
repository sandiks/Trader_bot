
#require 'bittrex'
require 'sequel'

require 'dotenv'
Dotenv.load('.env')
require_relative 'lib/client'
require_relative 'bittrex/db_util'


#p Bittrex::Quote.current('BTC-TIX')
#p Bittrex::Wallet.all.map { |ll| [ll.currency,ll.available, ll.balance]  }

#p Bittrex::Order.open
cln = Bittrex::Client.new({key:ENV["Key"], secret:ENV["Secret"] })

#p cln.get('account/getorderhistory').map { |rr| rr["Exchange"]  }
#p cln.get('market/getopenorders', {market:'BTC-XVC'})#.map { |ll|Balance  p [ll["Currency"], ll["Balance"] ]  }


#DB.run("truncate table my_balances")
pid=get_profile
exit if pid<2

DB[:my_balances].filter(pid: pid).delete

cln.get('account/getbalances')["result"].map do |rr| 
  
    if rr['Balance']>0
     
      curr = rr['Currency']
      p dd= { currency:curr, Balance:rr['Balance'],Available:rr['Available'],Pending:rr['Pending']}

      rec = DB[:my_balances].filter(pid:pid, currency:curr)
      upd =rec.update(dd)
      if 1 != upd 
        DB[:my_balances].insert( dd.merge(pid:pid) )
      end     

    end 
  #  DB[:my_balances].where(currency:sym).delete
  #  DB[:my_balances].insert(rr)
end
 