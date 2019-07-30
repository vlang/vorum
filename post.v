module main

import time

struct Post {
	id string
	title string
	text string 
	url string
	nr_comments int
	time string 
}

struct Comment {
	name string 
	text string 
	time string 
} 

fn (app mut App) find_all_posts() []Post {
	rows := app.db.exec(' 
select id, title, extract(epoch from time)::int, extract(epoch from last_reply)::int, nr_comments 
from posts 
order by last_reply desc')
	if rows.len == 0 {
		app.cur_user.name = 'admin' 
		app.insert_post('Hello world!', 'Hello world from vorum ;)') 
		return [Post{title:'Hello world!', text: 'Hello world from vorum ;)'}]  
	}
	mut posts := []Post
	for row in rows {
		id := row.vals[0] 
		title := row.vals[1]
		posts << Post {
			id: id 
			url : '/post/$id/' + clean_url(title) 
			title: title
			nr_comments: row.vals[4].int() 
			time: time.unix(row.vals[3].int()).clean() 
		}
	}
	return posts

}

fn (app App) find_comments(post_id int) []Comment {
	rows := app.db.exec('select * from comments where post_id=$post_id order by id')
	mut comments := []Comment 
	for row in rows {
	         text := row.vals[2].replace('\n', '<br>')
	         name := row.vals[3]
		comments << Comment {
			name: name
			text: text 
			time: time.unix(row.vals[5].int()).clean() 
		} 
	}
	return comments 
} 

fn (app App) retrieve_post(id int) ?Post { 
	rows := app.db.exec('select title, text, is_blog from posts where id=$id')
	if rows.len == 0 {
		return error('no posts')
	}
	row := rows[0]
	post := Post {
		title: row.vals[0]
		text: row.vals[1]
		id: id.str() 
	}
	return post
}

fn (app mut App) insert_comment(post_id int, comment Comment) bool { 
	app.db.exec_param2(' 
insert into comments 
(name, text, post_id) 
values 
($1,$2, \'$post_id\') ',	comment.name, comment.text)
	app.db.exec_param(' 
update posts 
set nr_comments=nr_comments+1, last_reply=now()::timestamp 
where id=$1', post_id.str())
	return true // TODO vweb $ hack 
} 

fn (app mut App) insert_post(title, text string) bool { 
	app.db.exec_param2('insert into posts (title, text) values ($1,$2)', title, '') 
	post_id := app.db.q_int('select id from posts order by id desc limit 1')
	app.db.exec_param2('insert into comments (name, text, post_id) values ($1, $2, \'$post_id\') ',
	app.cur_user.name, text)
	return true // TODO vweb $ hack 
} 

fn clean_url(s string) string {
        return s.replace(' ', '-').to_lower() 
} 
