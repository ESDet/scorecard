# Dependencies

## Ruby - v2.0+

## Mysql
```
brew install mysql
```

Add this to my.cnf
```
innodb_file_per_table
innodb_file_format = Barracuda
```

## Geos
```
brew install geos
```

## Proj4
```
brew install proj
```

# Install Gems

```
bundle install
```

# Database Setup

```
bundle exec rake db:create
bundle exec rake import:all
```
