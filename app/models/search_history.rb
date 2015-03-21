class SearchHistory
	def self.add_search_data(user_ip, search_keyword)
		
		$redis.lpush user_ip, search_keyword
	end

	def self.find_user_search_history(user_ip)
		$redis.lrange user_ip, 0, -1

	end

end