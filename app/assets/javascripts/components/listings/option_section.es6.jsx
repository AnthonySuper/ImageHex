import OptionFields from './option_fields.es6.jsx';

class OptionSection extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      options: props.options,
      deletedOptions: []
    };
  }

  render() {
    var options = this.state.options.map((o, i) => {
      return <OptionFields
          option={o}
          index={i}
          quoteOnly={this.props.quoteOnly}
          removeSelf={this.removeOption.bind(this, i)}
          id={i} />
    });

    return <div>
      <ul className="options-container">
        {options}
      </ul>
      <button type="button"
        onClick={this.addOption.bind(this)}>
        Add an Option
      </button>
    </div>;
  }

  addOption() {
    var n = [...this.state.options, {}];
    this.setState({
      options: n
    });
  }

  removeOption(index) {
    this.state.options.splice(index, 1);
    this.setState({
      options: this.state.options
    });
  }
}

export default OptionSection;
