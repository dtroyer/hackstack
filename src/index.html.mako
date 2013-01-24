<%inherit file="_templates/site.mako" />
<article class="page_box">
<%self:filter chain="markdown">

HackStack
=========

OpenStack hacking and more...

<ul>
  % for post in bf.config.blog.iter_posts_published(5):
    <li><a href="${post.path}">${post.title}</a></li>
  % endfor
</ul>

</%self:filter>
</article>
