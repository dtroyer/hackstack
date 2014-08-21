<%inherit file="_templates/site.mako" />
<article class="page_box">
<%self:filter chain="markdown">

% for post in bf.config.blog.iter_posts_published(10):
  <%include file="blog/post_excerpt.mako" args="post=post" />
% endfor

</%self:filter>
</article>
