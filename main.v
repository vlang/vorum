module main

import (
	net
	http 
	vweb
	os
	pg
)

const (
	Port = 8092
)

struct App {
pub mut:
	vweb vweb.Context // TODO embed 
	db pg.DB
	cur_user User 
}

fn main() {
	println('Running vorum on http://localhost:$Port')
	vweb.run<App>(Port)
}

pub fn (app mut App) init() {
	app.db = pg.connect('blog', 'alex')
	app.cur_user = User{} 
}

pub fn (app mut App) index() {
	posts := app.find_all_posts()
	println(123) // TODO remove, won't work without it 
	$vweb.html()
}

// TODO ['/post/:id/:title'] 
// TODO `fn (app App) post(id int)` 
pub fn (app App) post() {
	id := app.get_post_id() 
	post := app.retrieve_post(id) or {
		app.vweb.redirect('/') 
		return 
	}
	comments := app.find_comments(id)
	show_form := true 
	$vweb.html()
}

// new post 
pub fn (app App) new() {
	$vweb.html() 
} 

// [post] 
pub fn (app mut App) new_post() {
	mut name := '' 
	if app.cur_user.name != '' {
		name = app.cur_user.name
	}
	else {
		// not logged in
		//return
		name = 'admin' // TODO remove 
	}
	title := app.vweb.post_form['title']
	mut text := app.vweb.post_form['text']
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
	post_id := app.get_post_id() 
	mut name := ''// b.post_form['name']
	if app.cur_user.name != '' {
		name = app.cur_user.name
	}
	else {
		// not logged in
		//return
		name = 'admin' // TODO remove 
	}
	mut comment_text := app.vweb.post_form['text']
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
pub fn (app App) get_post_id() int {
	return app.vweb.req.url.substr(4, app.vweb.req.url.len).find_between('/', '/').int() 
} 


