import NM from '../../api/global.es6';
import PaginationControls from './pagination_controls.es6.jsx';
import 'babel-polyfill';
import Comment from './comment.es6.jsx';

class CommentsView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentPage: 0,
      fetching: false,
      isVisible: false,
      sortBy: "asc",
      comments: []
    }
    this.sortBy = "asc";
  }

  render() {
    console.log(this);
    if(! this.state.isVisible || ! this.state.comments) {
      return <div ref={(r) => this.overallContainer = r}>
        </div>;
    }
    if(this.state.fetching) {
      return <div>
        <progress></progress>
      </div>;
    }

    var cmts = this.state.comments.map((c) => <Comment {...c} key={c.id} />);
    return <div className="comments-outer">
      <h3>Comments</h3>
      <select className="comments-sort-select"
        onChange={this.changeSort.bind(this)}
        value={this.state.sortBy}>
        <option value="desc">Descending</option>
        <option value="asc">Ascending</option>
      </select>
      <div>
        {cmts}
      </div>
      <PaginationControls
        current={this.state.currentPage}
        totalPages={this.state.totalPages}
        changeTo={this.changePage.bind(this)} />
    </div>;
  }

  changeSort(event) {
    this.sortBy = event.target.value;
    if(this.state.sortBy !== event.target.value) {
      console.log("Changing sort to",event.target.value);
      // For some reason this setState isn't finishing by the time we're in
      // the fetch, so set sort manually:
      this.setState({
        sortBy: event.target.value,
        currentPage: 1
      });
      this.fetchCurrent();
    }
  }

  changePage(page) {
    this.setState({
      currentPage: page
    });
    this.fetchCurrent();
  }

  componentDidMount() {
    console.log("Adding a scroll handler");
    $("body").on("scroll.comments", (event) => {
      var r = $(this.overallContainer)[0].getBoundingClientRect();
      if(r.bottom <= window.innerHeight && ! this.state.fetching) {
        this.setState({
          currentPage: 1,
          isVisible: true
        });
        $("body").off("scroll.comments");
        this.fetchCurrent();
      }
    });
  }

  async fetchCurrent() {
    if(this.state.fetching) {
      return;
    }
    this.setState({
      fetching: true
    });
    console.log("Getting current with state",this.state);
    let url = this.props.url + `.json?page=${this.state.currentPage}`;
    url += `&sort=${this.sortBy}`;
    var res = await NM.getJSON(url);
    this.setState({
      comments: res.comments,
      totalPages: res.total_pages,
      fetching: false
    });
  }
}

$(document).on("page:change", function() {
  var box = $(".comments-container");
  if(box.length === 0) {
    console.log("Length zero, returning.");
    return;
  }
  ReactDOM.render(<CommentsView
    url={box.data("url")} />, box[0]);
});
