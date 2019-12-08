module main

import time

struct Post {
	id string
	title string
	text string
	url string
	nr_comments int
	time string
	nr_views int
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
println(rows.len)
	if rows.len == 0 {
		app.user.name = 'admin'
		app.insert_post('Hello world!', 'Hello world from Vorum ;)')
		return [Post{title:'Hello world!', text: 'Hello world from Vorum ;)'}]
	}
	mut posts := []Post
	for row in rows {
		id := row.vals[0]
		title := row.vals[1]
		mut t:= time.unix(row.vals[3].int()).clean()
		// Only display "Dec 8", not "Dec 8 12:30"
		if j := t.index(' ') {
			i := t.last_index(' ')
			if i != j {
				t = t[..i]
			}
		}
		posts << Post {
			id: id
			url : '/post/$id/' + clean_url(title)
			title: title
			nr_comments: row.vals[4].int()
			time: t//time.unix(row.vals[3].int()).clean()
		}
	}
	return posts

}

fn (app App) find_comments(post_id int) []Comment {
	rows := app.db.exec('select * from comments where post_id=$post_id order by id')
	mut comments := []Comment
	for row in rows {
	         text := row.vals[2]
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

fn (app & App) insert_comment(post_id int, comment Comment) bool {
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

fn (app & App) insert_post(title, text string) bool {
	app.db.exec_param2('insert into posts (title, text) values ($1,$2)', title, '')
	post_id := app.db.q_int('select id from posts order by id desc limit 1')
	app.db.exec_param2('insert into comments (name, text, post_id) values ($1, $2, \'$post_id\') ',
	app.user.name, text)
	return true // TODO vweb $ hack
}

fn clean_url(s string) string {
	mut buf := [50]byte
	mut j := 0
	for i, c in s {
		if i >= 50 {
			break
		}
		if !c.is_letter() {
			if j > 0 && i < s.len - 1 && buf[j-1] != `-`  {
				buf[j] = `-`
				j++
			}
			continue
		}
		buf[j] = c
		j++

	}
	return tos_clone(buf)
}

fn (c &Comment) filtered_text() string {
	res := c.text.replace_each([
		'\n', '<br>',
		'<', '&lt;',
		'[b]', '<b>',
		'[/b]', '</b>',
	])
	println('"$c.text"')
	println('"$res"' + '\n\n')
	return res

	// http links
	/*
	mut s := c.text
	if c.text.contains('https://') {
		println('\n\n' + c.text)
		mut pos := 0
		for {
			pos = c.text.index_after('https://', pos)
			if pos == -1 {
				break
			}
			mut end := pos
			for c.text[end] != ` ` && end < c.text.len - 1 {
				end++
			}
			//println('!!!!! $pos .. $end')
			link := c.text[pos..end+1]
			println(link)
			s = s.replace(link, '<a target=_blank href="$link">$link</a>')
			pos ++
		}
	}
	return s
	*/


}

