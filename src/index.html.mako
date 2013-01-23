<%inherit file="_templates/site.mako" />
<article class="page_box">
<%self:filter chain="markdown">

HackStack
=========

The thoughts of some guy.

<ul>
% for post in bf.config.blog.posts[:5]:
  % if not post.draft:
    <%include file="blog/post_excerpt.mako" args="post=post" />
  % endif
% endfor
</ul>

</%self:filter>
</article>
