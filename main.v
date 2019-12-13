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
	user User
	logged_in bool
}

pub fn (app mut App) reset() {
	app.user = User{}
	app.logged_in = false
}


fn main() {
	println('Running vorum on http://localhost:$port')
	mut app := App{}
	vweb.run(mut app, port)
}

pub fn (app mut App) init() {
	db := pg.connect(pg.Config{host:'127.0.0.1', dbname:db_name, user:db_user}) or { panic(err) }
	app.db = db
	app.user = User{}
}

pub fn (app mut App) index() {
	app.auth()
	posts := app.find_all_posts()
	//println('number of posts=$posts.len')
	$vweb.html()
}

// TODO ['/post/:id/:title']
// TODO `fn (app App) post(id int)`
pub fn (app mut App) post() {
	id := app.get_post_id()
	post := app.retrieve_post(id) or {
		app.vweb.text('Discussion not found.')
		return
	}
	app.auth()
	comments := app.find_comments(id)
	$vweb.html()
}

// new post
pub fn (app mut App) new() {
	app.auth()
	$vweb.html()
}

// [post]
pub fn (app mut App) new_post() {
	app.auth()
	mut name := ''
	if app.user.name != '' {
		name = app.user.name
	} else {
		// not logged in
		app.vweb.redirect('/new')
		return
	}
	title := app.vweb.form['title']
	text := app.vweb.form['text']
	if title == '' || text == '' {
		app.vweb.redirect('/new')
		return
	}
	app.insert_post(title.replace('<', '&lt;'), text)
	app.vweb.redirect('/')
}

// [post]
fn (app mut App) comment() {
	app.auth()
	post_id := app.get_post_id()
	if !app.logged_in {
		app.vweb.redirect('/')
		return
	}
	comment_text := app.vweb.form['text']
	if comment_text == '' {
		//app.vweb.redirect('/')
		app.vweb.text('Empty message.')
		return
	}
	app.insert_comment(post_id,  Comment{
		text: comment_text
		name: app.user.name
	})
	app.vweb.redirect('/post/$post_id')// so that refreshing a page won't do a post again
}

pub fn (app mut App) deletepost() {
	app.auth()
	if !app.user.is_admin {
		app.vweb.redirect('/')
		return
	}
	post_id := 1
	db := app.db
	//db.update Post set nr_comments=10//  is_deleted = true where id = post_id
	db.update Post set is_deleted = true where id == post_id
	println('deleted post $post_id')
}

pub fn (app mut App) logoff() {
	app.vweb.set_cookie('id', '')
	app.vweb.set_cookie('q', '')
	app.vweb.redirect('/')
}


// "/post/:id/:title"
pub fn (app &App) get_post_id() int {
	return app.vweb.req.url[4..].find_between('/', '/').int()
}


