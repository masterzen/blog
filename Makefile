build:
	JEKYLL_ENV=production bundle exec jekyll b


push: build
	rsync -avz --delete --exclude patches --exclude favicon.png --exclude img --exclude .well-known _site/ brice@vps345869.ovh.net:/var/www/www.masterzen.fr/


serve:
	JEKYLL_ENV=production bundle exec jekyll s --drafts --incremental

