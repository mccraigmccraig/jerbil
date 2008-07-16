## maintainer stuff

namespace :maintainer do 
	WWWROOT   = "/var/www/code.trampolinesystems.com/"
	
	task :publish_doc  do |t|
		sh "scp -r rdoc/* trampolinesystems.com:#{WWWROOT}/doc/jerbil/"
	end
	task :publish_doc => :rerdoc
	
	task :copy_gem do |t|
		sh "scp pkg/* trampolinesystems.com:#{WWWROOT}/gems"
	end
	task :copy_gem => :repackage
	
	task :update_gem_index do |t|
		sh "ssh trampolinesystems.com gem generate_index -d #{WWWROOT}"
	end
	
	task :publish_gem => [:copy_gem, :update_gem_index]
	
	task :publish => [ :test, :compile_classloader, :publish_gem, :publish_doc ]
end
