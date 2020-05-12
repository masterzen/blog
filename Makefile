build:
	JEKYLL_ENV=production bundle exec jekyll b


push:
	rsync -avz --delete --exclude patches --exclude favicon.png --exclude img _site/ brice@vps345869.ovh.net:/var/www/www.masterzen.fr/

