echo "From which site would you like to download the text?"
read varname_link

curl "$varname_link" -o 'scraped_webpage.html'
