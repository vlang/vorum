module main

import (
	net
	http
	vweb
	os
	pg
)

const (
	port = 8092
	db_name = 'vorum'
	db_user = 'alex'
)

struct App {
pub mut:
	vweb vweb.Context // TODO embed
	db pg.DB
	cur_user User
}

pub fn (app mut App) reset() {
	app.cur_user = User{}
}


fn main() {
	println('Running vorum on http://localhost:$port')
	mut app := App{}
	vweb.run(mut app, port)
}

pub fn (app mut App) init() {
	db := pg.connect(pg.Config{host:'127.0.0.1', dbname:db_name, user:db_user}) or { panic(err) }
	app.db = db
	app.cur_user = User{}
}

pub fn (app mut App) index() {
	posts := app.find_all_posts()
	println(123) // TODO remove, won't work without it
	$vweb.html()
}

// TODO ['/post/:id/:title']
// TODO `fn (app App) post(id int)`
pub fn (app mut App) post() {
	id := app.get_post_id()
	post := app.retrieve_post(id) or {
		app.vweb.redirect('/')
		return
	}
	app.auth()
	comments := app.find_comments(id)
	show_form := app.cur_user.name != ''
	$vweb.html()
}

// new post
pub fn (app mut App) new() {
	app.auth()
	logged_in := app.cur_user.name != ''
	$vweb.html()
}

// [post]
pub fn (app mut App) new_post() {
	app.auth()
	mut name := ''
	if app.cur_user.name != '' {
		name = app.cur_user.name
	} else {
		// not logged in
		app.vweb.redirect('/new')
		return
	}
	title := app.vweb.form['title']
	mut text := app.vweb.form['text']
	if title == '' || text == '' {
		app.vweb.redirect('/new')
		return
	}
	// Allow admin to post HTML
	if name != 'admin' {
		text = text.replace('<', '&lt;')
	}
	app.insert_post(title, text)
	app.vweb.redirect('/')
}

// [post]
fn (app mut App) comment() {
	app.auth()
	post_id := app.get_post_id()
	mut name := ''// b.form['name']
	if app.cur_user.name != '' {
		name = app.cur_user.name
	}
	else {
		// not logged in
		app.vweb.redirect('/')
		return
	}
	mut comment_text := app.vweb.form['text']
	if name == '' || comment_text == '' {
		return
	}
	// Allow admin to post HTML
	if name != 'admin' {
		comment_text = comment_text.replace('<', '&lt;')
	}
	app.insert_comment(post_id,  Comment{ text: comment_text, name: name })
	app.vweb.redirect('/post/$post_id')// so that refreshing a page won't do a post again
}


// "/post/:id/:title"
pub fn (app &App) get_post_id() int {
	return app.vweb.req.url[4..app.vweb.req.url.len].find_between('/', '/').int()
}


