module main

import vweb
import db.pg
import net.http
import time
import log

const (
	port    = 8092
	db_name = 'vorum'
	db_user = 'vorum'
)

pub struct App {
	vweb.Context
pub mut:
	db        pg.DB
	user      User
	logged_in bool
	logger    log.Log [vweb_global]
}

fn main() {
	println('Running Vorum on http://localhost:${port}')

	mut app := &App{}
	app.init()

	vweb.run(app, port)
}

pub fn (mut app App) init() {
	app.db = pg.connect(pg.Config{ host: '127.0.0.1', dbname: db_name, user: db_user }) or {
		panic(err)
	}
	app.user = User{}
	app.setup_logger()
}

pub fn (mut app App) index() vweb.Result {
	app.auth()
	posts := app.find_all_posts() or {
		app.warn(err.str())

		return app.ok('')
	}

	return $vweb.html()
}

['/post/:id']
pub fn (mut app App) post(id int) vweb.Result {
	post := app.get_post(id) or { return app.text('Discussion not found.') }
	app.inc_post_views(id) or { app.warn(err.str()) }
	app.auth()

	comments := app.find_comments(id) or {
		app.warn(err.str())
		[]Comment{}
	}

	return $vweb.html()
}

pub fn (mut app App) new() vweb.Result {
	app.auth()

	return $vweb.html()
}

[post]
pub fn (mut app App) new_post() vweb.Result {
	app.auth()

	if app.user.name == '' {
		// Not logged in
		return app.redirect('/new')
	}

	title := app.form['title']
	text := app.form['text']
	if title == '' || text == '' {
		return app.redirect('/new')
	}

	app.insert_post(title.replace('<', '&lt;'), text) or { app.warn(err.str()) }

	return app.redirect('/')
}

['/comment/:post_id'; post]
fn (mut app App) comment(post_id int) vweb.Result {
	app.auth()

	if !app.logged_in {
		return app.redirect('/')
	}

	comment_text := app.form['text']
	if comment_text == '' {
		return app.text('Empty message.')
	}

	app.insert_comment(post_id, Comment{
		text: comment_text
		name: app.user.name
	}) or { app.warn(err.str()) }

	return app.redirect('/post/${post_id}') // so that refreshing a page won't do a post again
}

['/posts/:id'; delete]
pub fn (mut app App) deletepost(post_id int) vweb.Result {
	app.auth()

	if !app.user.is_admin {
		return app.ok('')
	}

	sql app.db {
		delete from Post where id == post_id
	} or { app.warn(err.str()) }

	return app.ok('')
}

pub fn (mut app App) logoff() vweb.Result {
	app.set_cookie(http.Cookie{ name: 'id', value: '' })
	return app.redirect('/')
}

fn (mut app App) setup_logger() {
	app.logger.set_level(.debug)

	app.logger.set_full_logpath('./logs/log_${time.now().ymmdd()}.log')
	app.logger.log_to_console_too()
}

pub fn (mut app App) warn(msg string) {
	app.logger.warn(msg)

	app.logger.flush()
}

pub fn (mut app App) info(msg string) {
	app.logger.info(msg)

	app.logger.flush()
}

pub fn (mut app App) debug(msg string) {
	app.logger.debug(msg)

	app.logger.flush()
}
