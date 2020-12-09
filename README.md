# FeedReader

This is a concept RSS feed aggregator app written in Swift for iOS.

It was my first project written in Swift. I submitted the code for a national
competitive event, ventured to Anaheim, CA to present the app, and placed second in the US.

The app features background fetching, article categorization, marking for later reading, bulk actions,
easy sharing, and more.

## Code navigation

Backend
* [XMLParser](FeedReader/XMLParser.swift) - RSS XML parser implementation 
* [Feed](FeedReader/Feed.swift) - represents a feed
* [FeedGroup](FeedReader/FeedGroup.swift) - represents a user-created feed category
* [Article](FeedReader/Article.swift) - represents an article
* [ArticleCollection](FeedReader/ArticleCollection.swift) - represents a collection of articles
* [Manager](FeedReader/Manager.swift) - feed manager class
* [AppDelegate](FeedReader/AppDelegate.swift) - the application delegate

MVC
* [FeedListVC](FeedReader/FeedListVC.swift) - feed list view controller
* [ArticleListVC](FeedReader/ArticleListVC.swift) - article list view controller
* [ArticleWebVC](FeedReader/ArticleWebVC.swift) - article web view controller
* [GroupEditorVC](FeedReader/GroupEditorVC.swift) - feed group editor view controller
* [MasterSettingsVC](FeedReader/MasterSettingsVC.swift) - app settings view controller

## Screenshots

[![Screenshots](https://i.imgur.com/8MpjMFy.png) Screenshot gallery](https://mitchellcooper.me/screenshots/feedreader)

## License

[ISC](LICENSE)

## Author

[Mitchell Cooper](https://mitchellcooper.me), <mitchell@mitchellcooper.me>
