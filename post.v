module main

import time

[table: 'posts']
struct Post {
	id          int
	title       string
	text        string
	url         string    [skip]
	nr_comments int
	time        time.Time [orm: skip]
	last_reply  time.Time
	nr_views    int
	is_locked   bool
	is_blog     bool
	is_deleted  bool
}

[table: 'comments']
struct Comment {
	id      int
	post_id int
	name    string
	text    string
	time    time.Time
}

fn (mut app App) find_all_posts() ![]Post {
	rows := app.db.exec('
select id, title, extract(epoch from time)::int,
extract(epoch from last_reply)::int, nr_comments, is_locked
from posts
where is_deleted=false
order by last_reply desc')!

	if rows.len == 0 {
		app.user.name = 'admin'
		app.insert_post('Hello world!', 'Hello world from Vorum ;)')!
		return [
			Post{
				title: 'Hello world!'
				text: 'Hello world from Vorum ;). This is the conntent for the text'
			},
		]
	}
	mut posts := []Post{}
	for row in rows {
		id := row.vals[0]
		title := row.vals[1]
		posts << Post{
			id: id.int()
			url: '/post/${id}'
			title: title
			nr_comments: row.vals[4].int()
			time: time.unix(row.vals[3].int())
			is_locked: row.vals[5] == 't'
		}
	}
	return posts
}

fn (app &App) inc_post_views(post_id int) ! {
	sql app.db {
		update Post set nr_views = nr_views + 1 where id == post_id
	}!
}

fn (app App) find_comments(post_id int) ![]Comment {
	return sql app.db {
		select from Comment where post_id == post_id order by id
	} or { []Comment{} }
}

fn (mut app App) get_post(post_id int) ?Post {
	posts := sql app.db {
		select from Post where id == post_id limit 1
	} or {
		app.warn(err.str())
		[]Post{}
	}

	if posts.len == 0 {
		return none
	}

	return posts.first()
}

fn (app &App) insert_comment(post_id int, comment Comment) ! {
	app.db.exec_param2('
insert into comments
(name, text, post_id)
values
($1,$2, \'${post_id}\') ',
		comment.name, comment.text)!
	app.db.exec_param('
update posts
set nr_comments=nr_comments+1, last_reply=now()::timestamp
where id=$1',
		post_id.str())!
}

fn (app &App) insert_post(title string, text string) ! {
	app.db.exec_param2('insert into posts (title, text) values ($1,$2)', title, '')!
	post_id := app.db.q_int('select id from posts order by id desc limit 1')!
	app.db.exec_param2('insert into comments (name, text, post_id) values ($1, $2, \'${post_id}\') ',
		app.user.name, text)!
}

fn (c &Comment) filtered_text() string {
	return c.text.replace_each([
		'\n',
		'<br>',
		'<',
		'&lt;',
		'[b]',
		'<b>',
		'[/b]',
		'</b>',
		'[code]',
		'<pre>',
		'[/code]',
		'</pre>',
	])
}
