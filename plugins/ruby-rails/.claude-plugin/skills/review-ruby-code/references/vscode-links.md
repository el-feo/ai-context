# VSCode Links Reference

This guide explains how to create VSCode-compatible file links in REVIEW.md that allow reviewers to click and jump directly to the relevant line of code.

## Link Format

### Basic Structure

```markdown
[descriptive text](file:///absolute/path/to/file.rb#L123)
```

**Components**:
- `file://` - URI scheme for local files (note: three slashes total)
- `/absolute/path/to/file.rb` - Complete absolute path to the file
- `#L123` - Line number anchor (capital L followed by line number)

### Important Rules

1. **Must use absolute paths** - Relative paths won't work
2. **Three slashes after file:** - `file:///` not `file://`
3. **Capital L in line anchor** - `#L42` not `#l42` or `#42`
4. **No spaces in path** - URL encode spaces as `%20` if necessary
5. **Forward slashes** - Even on Windows, use `/` not `\`

## Examples

### Basic File Reference

```markdown
[UserService#create violates SRP](file:///Users/dev/myapp/app/services/user_service.rb#L23)
```

Clicking this opens `app/services/user_service.rb` at line 23 in VSCode.

### Controller Action

```markdown
[Missing authorization check in destroy action](file:///Users/dev/myapp/app/controllers/posts_controller.rb#L45)
```

### Model Method

```markdown
[N+1 query in Post#recent_comments](file:///Users/dev/myapp/app/models/post.rb#L67)
```

### View Template

```markdown
[XSS vulnerability using html_safe](file:///Users/dev/myapp/app/views/posts/show.html.erb#L12)
```

### Test File

```markdown
[Missing test for edge case](file:///Users/dev/myapp/spec/models/user_spec.rb#L89)
```

## Constructing Links Programmatically

### Ruby Code to Generate Links

```ruby
def vscode_link(description, file_path, line_number)
  absolute_path = File.expand_path(file_path)
  "[#{description}](file://#{absolute_path}#L#{line_number})"
end

# Usage
vscode_link(
  "UserService#create violates SRP",
  "app/services/user_service.rb",
  23
)
# => "[UserService#create violates SRP](file:///Users/dev/myapp/app/services/user_service.rb#L23)"
```

### Get Absolute Path

```ruby
# From relative path
absolute_path = File.expand_path("app/models/user.rb")
# => "/Users/dev/myapp/app/models/user.rb"

# From git root
git_root = `git rev-parse --show-toplevel`.strip
file_path = File.join(git_root, "app/models/user.rb")
# => "/Users/dev/myapp/app/models/user.rb"
```

### Finding Line Numbers

When analyzing code, capture the line number from grep output:

```bash
# Grep with line numbers
grep -n "def create" app/services/user_service.rb
# => 23:  def create

# In Ruby
line_number = File.readlines(file_path).find_index { |line| line.include?("def create") } + 1
```

## Integration with Code Review

### REVIEW.md Structure

```markdown
## Design & Architecture

### OOP Violations

#### Single Responsibility Principle

**UserService class has too many responsibilities** ([app/services/user_service.rb#L1](file:///Users/dev/myapp/app/services/user_service.rb#L1))

The `UserService` class handles:
- User creation ([line 23](file:///Users/dev/myapp/app/services/user_service.rb#L23))
- Email sending ([line 45](file:///Users/dev/myapp/app/services/user_service.rb#L45))
- Payment processing ([line 67](file:///Users/dev/myapp/app/services/user_service.rb#L67))
- Analytics tracking ([line 89](file:///Users/dev/myapp/app/services/user_service.rb#L89))

**Recommendation**: Extract each responsibility into separate service objects.
```

### Inline Code References

Every code reference should be clickable:

```markdown
The method [`Post#recent_comments`](file:///Users/dev/myapp/app/models/post.rb#L34)
causes an N+1 query. Each iteration at
[line 36](file:///Users/dev/myapp/app/models/post.rb#L36) loads comments
individually instead of eager loading them.
```

## Testing Links

### Manual Testing

After generating REVIEW.md:

1. Open REVIEW.md in VSCode
2. Click each link
3. Verify it opens the correct file at the correct line

### Automated Verification

```ruby
# Verify all links in REVIEW.md point to existing files
review_content = File.read('REVIEW.md')

# Extract all file:// links
links = review_content.scan(/file:\/\/(.*?)#L(\d+)/)

links.each do |file_path, line_number|
  unless File.exist?(file_path)
    puts "ERROR: File not found: #{file_path}"
  end

  line_count = File.readlines(file_path).count
  if line_number.to_i > line_count
    puts "ERROR: Line #{line_number} exceeds file length (#{line_count}) in #{file_path}"
  end
end
```

## Common Issues and Solutions

### Issue 1: Links Don't Open

**Problem**: Clicking link does nothing

**Solutions**:
- Ensure three slashes: `file:///` not `file://`
- Check absolute path is correct
- Verify VSCode is default handler for `file://` protocol

### Issue 2: Opens Wrong Line

**Problem**: Opens file but wrong line number

**Solutions**:
- Verify line number is correct
- Use capital `L`: `#L42` not `#l42`
- Check line hasn't changed since review

### Issue 3: Path with Spaces

**Problem**: Path contains spaces and link breaks

**Solution**: URL encode spaces
```ruby
path_with_spaces = "/Users/dev/my app/models/user.rb"
encoded_path = path_with_spaces.gsub(' ', '%20')
# => "/Users/dev/my%20app/models/user.rb"
```

### Issue 4: Windows Paths

**Problem**: Windows uses backslashes

**Solution**: Convert to forward slashes
```ruby
windows_path = "C:\\Users\\dev\\myapp\\app\\models\\user.rb"
unix_style_path = windows_path.gsub('\\', '/')
# => "C:/Users/dev/myapp/app/models/user.rb"

link = "file:///#{unix_style_path}#L23"
```

## Alternative Link Formats

### GitHub Links (for remote review)

If review is done in GitHub/GitLab instead of locally:

```markdown
[UserService#create](https://github.com/user/repo/blob/main/app/services/user_service.rb#L23)
```

**Format**: `https://github.com/{user}/{repo}/blob/{branch}/{file}#L{line}`

### Relative GitHub Links

For repository-specific reviews:

```markdown
[UserService#create](app/services/user_service.rb#L23)
```

GitHub automatically converts these to proper links when viewed in the repository.

## Best Practices

### 1. Consistent Link Text

Use descriptive, consistent link text:

**Good**:
```markdown
[UserService#create_user violates SRP](file://...)
[Post#recent_comments causes N+1](file://...)
[Missing authorization in PostsController#destroy](file://...)
```

**Bad**:
```markdown
[here](file://...)
[click here](file://...)
[this](file://...)
```

### 2. Multiple References to Same Location

If referencing the same location multiple times, be consistent:

```markdown
The [`UserService#create`](file://...#L23) method is too long (violates Sandi Metz Rule 2)
and has too many responsibilities (violates SRP). Consider refactoring
[`UserService#create`](file://...#L23) into smaller methods.
```

### 3. Range References

For multi-line issues:

```markdown
The method [`UserService#create`](file:///Users/dev/myapp/app/services/user_service.rb#L23)
spans [lines 23-67](file:///Users/dev/myapp/app/services/user_service.rb#L23),
exceeding the 5-line limit.
```

### 4. Class-Level References

For class-level issues, link to class definition:

```markdown
[`UserService` class](file:///Users/dev/myapp/app/services/user_service.rb#L1)
has 150 lines, violating the 100-line limit.
```

## Example Review Section with Links

```markdown
## OOP Design Issues

### Single Responsibility Principle Violations

1. **UserService has multiple responsibilities**
   ([UserService](file:///Users/dev/myapp/app/services/user_service.rb#L1))

   - User creation at [line 23](file:///Users/dev/myapp/app/services/user_service.rb#L23)
   - Email notifications at [line 45](file:///Users/dev/myapp/app/services/user_service.rb#L45)
   - Payment processing at [line 67](file:///Users/dev/myapp/app/services/user_service.rb#L67)

   **Recommendation**: Split into `UserCreator`, `UserNotifier`, and `UserPaymentProcessor`.

2. **Long method violates 5-line rule**
   ([OrderProcessor#process](file:///Users/dev/myapp/app/services/order_processor.rb#L12))

   The `process` method spans 25 lines. Extract to smaller, focused methods:
   - Extract validation logic ([lines 13-18](file:///Users/dev/myapp/app/services/order_processor.rb#L13))
   - Extract payment processing ([lines 19-25](file:///Users/dev/myapp/app/services/order_processor.rb#L19))
   - Extract notification sending ([lines 26-30](file:///Users/dev/myapp/app/services/order_processor.rb#L26))
```

## Summary

**Required elements for each code reference**:
1. Descriptive link text indicating what/where the issue is
2. `file:///` protocol with three slashes
3. Absolute path to file
4. `#L{number}` line anchor with capital L

**Every line of code mentioned in REVIEW.md must be clickable.**
